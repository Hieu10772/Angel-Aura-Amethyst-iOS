package net.kdt.pojavlaunch;

import java.beans.Beans;
import java.io.*;
import java.lang.reflect.Field;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.util.*;
import java.util.concurrent.*;
import java.util.zip.*;

import org.lwjgl.glfw.CallbackBridge;
import org.lwjgl.glfw.GLFW;

import net.kdt.pojavlaunch.uikit.*;
import net.kdt.pojavlaunch.utils.*;
import net.kdt.pojavlaunch.value.*;

public class PojavLauncher {
    private static float currProgress, maxProgress;

    public static void main(String[] args) throws Throwable {
        // Skip calling to com.apple.eawt.Application.nativeInitializeApplicationDelegate()
        Beans.setDesignTime(true);
        try {
            // Some places use macOS-specific code, which is unavailable on iOS
            // In this case, try to get it to use Linux-specific code instead.
            com.apple.eawt.Application.getApplication();
            Class clazz = Class.forName("com.apple.eawt.Application");
            Field field = clazz.getDeclaredField("sApplication");
            field.setAccessible(true);
            field.set(null, null);
            sun.font.FontUtilities.isLinux = true;
            System.setProperty("java.util.prefs.PreferencesFactory", "java.util.prefs.FileSystemPreferencesFactory");
        } catch (Throwable th) {
            // Not on JRE8, ignore exception
            //Tools.showError(th);
        }

        // Ensure JNA uses a writable directory with valid code signing support
        String pojavHome = System.getenv("POJAV_HOME");
        if (pojavHome != null) {
            String jnaTmpDir = pojavHome + "/jna_tmp";
            new File(jnaTmpDir).mkdirs();
            System.setProperty("jna.tmpdir", jnaTmpDir);
            System.setProperty("jna.nosys", "true");
            System.setProperty("jna.boot.library.path", jnaTmpDir);
        }

        // Skip JNA's internal class-initialization that tries to dlopen dyld
        // shared-cache images (non-existent on iOS), preventing spurious
        // UnsatisfiedLinkError during Native.<clinit>
        System.setProperty("jna.nounpack", "true");
        System.setProperty("jna.noclassinit", "true");

        Thread.currentThread().setUncaughtExceptionHandler(new Thread.UncaughtExceptionHandler() {

            public void uncaughtException(Thread t, Throwable th) {
                System.err.println("===== UNCAUGHT EXCEPTION on thread: " + t.getName() + " =====");
                th.printStackTrace();
                System.err.println("===== END UNCAUGHT EXCEPTION =====");
                System.err.flush();
                System.out.flush();
                try { Thread.sleep(500); } catch (InterruptedException e) {}
                System.exit(1);
            }
        });

        try {
            // Try to initialize Caciocavallo17
            Class.forName("com.github.caciocavallosilano.cacio.ctc.CTCPreloadClassLoader");
        } catch (ClassNotFoundException e) {}

        String runJar = System.getProperty("pojav.runJar");
        if (runJar != null) {
            UIKit.callback_JavaGUIViewController_launchJarFile(runJar, new String[0]);
        } else {
            try {
                launchMinecraft(args);
            } catch (Throwable th) {
                System.err.println("===== FATAL ERROR in launchMinecraft =====");
                th.printStackTrace();
                System.err.println("===== END FATAL ERROR =====");
                System.exit(1);
            }
        }
    }

    private static String downloadLog4jConfig(JMinecraftVersionList.LoggingConfig logging) {
        if (logging == null || logging.client == null || logging.client.file == null) return null;
        String fileId = logging.client.file.id;
        String fileUrl = logging.client.file.url;
        if (fileId == null) return null;

        // Known bundled configs
        if ("client-1.12.xml".equals(fileId)) {
            return Tools.DIR_BUNDLE + "/log4j-rce-patch-1.12.xml";
        }
        if ("client-1.7.xml".equals(fileId)) {
            return Tools.DIR_BUNDLE + "/log4j-rce-patch-1.7.xml";
        }

        // For unknown config IDs, try to download from the provided URL
        if (fileUrl == null) return null;

        String localPath = Tools.DIR_GAME_NEW + "/log4j/" + fileId;
        File localFile = new File(localPath);
        if (localFile.exists()) {
            return localPath;
        }

        try {
            System.out.println("Downloading log4j config: " + fileId + " from " + fileUrl);
            localFile.getParentFile().mkdirs();
            URL url = new URL(fileUrl);
            try (InputStream in = url.openStream()) {
                Files.copy(in, localFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
            }
            System.out.println("Downloaded log4j config to: " + localPath);
            return localPath;
        } catch (Exception e) {
            System.err.println("Failed to download log4j config: " + fileId + " - " + e.getMessage());
            return null;
        }
    }

    // ============ LWJGL Library-order fix ============
    // The game's LWJGL (Fabric/Knot classloader) fails on JDK 25+ because eager
    // class init during System.load of the native executable initializes
    // org.lwjgl.glfw.GLFW before liblwjgl.dylib is registered: GLFWErrorCallbackI
    // <clinit> -> LibFFI.<clinit> -> FFI_TYPE_DOUBLE() throws UnsatisfiedLinkError
    // ("Could not initialize class org.lwjgl.glfw.GLFW"). Older builds of the
    // lwjgl jar call System.load(app binary) BEFORE loadSystem("org.lwjgl").
    // This patches the instance's lwjgl core jar with the fixed Library.class
    // (loadSystem first), matching lwjgl41's build.
    private static void patchInstanceLwjgl() {
        byte[] fixedLibrary = readResourceBytes("/lwjglfix/Library.class");
        if (fixedLibrary == null) {
            System.out.println("[LWJGLFix] fixed Library.class resource missing, skipping");
            return;
        }
        int patched = 0;
        File gameDir = new File(Tools.DIR_GAME_NEW);
        List<File> jars = new ArrayList<>();
        try {
            Files.walk(gameDir.toPath()).filter(p -> p.toString().endsWith(".jar"))
                .forEach(p -> jars.add(p.toFile()));
        } catch (IOException e) {
            System.err.println("[LWJGLFix] walk failed: " + e);
            return;
        }
        for (File jar : jars) {
            try {
                if (patchJarLibraryClass(jar, fixedLibrary)) patched++;
            } catch (Exception e) {
                System.err.println("[LWJGLFix] failed on " + jar + ": " + e);
            }
        }
        System.out.println("[LWJGLFix] patched " + patched + " lwjgl jar(s) under " + gameDir);
    }

    private static boolean patchJarLibraryClass(File jar, byte[] fixedLibrary) throws IOException {
        byte[] oldBytes = readJarEntry(jar, "org/lwjgl/system/Library.class");
        if (oldBytes == null) return false;
        if (Arrays.equals(oldBytes, fixedLibrary)) return false;
        File tmp = new File(jar.getParentFile(), jar.getName() + ".lwjglfix.tmp");
        byte[] buf = new byte[65536];
        try (ZipInputStream zin = new ZipInputStream(new FileInputStream(jar));
             ZipOutputStream zout = new ZipOutputStream(new FileOutputStream(tmp))) {
            ZipEntry in;
            while ((in = zin.getNextEntry()) != null) {
                ZipEntry out = new ZipEntry(in.getName());
                out.setTime(in.getTime());
                zout.putNextEntry(out);
                if (in.getName().equals("org/lwjgl/system/Library.class")) {
                    zout.write(fixedLibrary);
                } else {
                    int n;
                    while ((n = zin.read(buf)) > 0) zout.write(buf, 0, n);
                }
                zout.closeEntry();
            }
        }
        if (!tmp.renameTo(jar)) {
            Files.move(tmp.toPath(), jar.toPath(), StandardCopyOption.REPLACE_EXISTING);
        }
        System.out.println("[LWJGLFix] replaced Library.class in " + jar);
        return true;
    }

    private static byte[] readJarEntry(File jar, String entryName) throws IOException {
        try (ZipFile zip = new ZipFile(jar)) {
            ZipEntry entry = zip.getEntry(entryName);
            if (entry == null) return null;
            try (InputStream in = zip.getInputStream(entry)) {
                ByteArrayOutputStream out = new ByteArrayOutputStream();
                byte[] buf = new byte[65536];
                int n;
                while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
                return out.toByteArray();
            }
        }
    }

    private static byte[] readResourceBytes(String path) {
        try (InputStream in = PojavLauncher.class.getResourceAsStream(path)) {
            if (in == null) return null;
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            byte[] buf = new byte[65536];
            int n;
            while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
            return out.toByteArray();
        } catch (IOException e) {
            return null;
        }
    }

    public static void launchMinecraft(String[] args) throws Throwable {
        // Args for Spiral Knights
        System.setProperty("appdir", "./spiral");
        System.setProperty("resource_dir", "./spiral/rsrc");

        String sizeStr = System.getProperty("cacio.managed.screensize");
        System.setProperty("glfw.windowSize", sizeStr);
        String[] size = sizeStr.split("x");
        MCOptionUtils.load();
        MCOptionUtils.set("fullscreen", "false");
        MCOptionUtils.set("overrideWidth", size[0]);
        MCOptionUtils.set("overrideHeight", size[1]);
        // Default settings for performance
        MCOptionUtils.setDefault("mipmapLevels", "0");
        MCOptionUtils.setDefault("particles", "1");
        MCOptionUtils.setDefault("renderDistance", "2");
        MCOptionUtils.setDefault("simulationDistance", "5");
        MCOptionUtils.save();

        // Setup Forge splash.properties
        File forgeSplashFile = new File(Tools.DIR_GAME_NEW, "config/splash.properties");
        if (System.getProperty("pojav.internal.keepForgeSplash") == null) {
            forgeSplashFile.getParentFile().mkdir();
            if (forgeSplashFile.exists()) {
                Tools.write(forgeSplashFile.getAbsolutePath(), Tools.read(forgeSplashFile.getAbsolutePath().replace("enabled=true", "enabled=false")));
            } else {
                Tools.write(forgeSplashFile.getAbsolutePath(), "enabled=false");
            }
        }

        System.setProperty("org.lwjgl.vulkan.libname", "libMoltenVK.dylib");

        // NOTE: SDL_SetMainReady is now called from the native side
        // (aasdl_setMainReady at pojavInit). Do NOT touch org.lwjgl.sdl.SDLMain
        // here: initializing LWJGL in the launcher's classloader preloads
        // liblwjgl.dylib, which then makes Fabric/Knot fail with
        // "Native Library liblwjgl.dylib already loaded in another classloader"
        // (Mojang's LWJGL runs in a separate classloader and tries to load the
        // same native library again).

        MinecraftAccount account = MinecraftAccount.load(args[0]);
        JMinecraftVersionList.Version version = Tools.getVersionInfo(args[1]);
        System.out.println("Launching Minecraft " + (version != null ? version.id : "null"));
        String configPath = downloadLog4jConfig(version != null ? version.logging : null);
        if (configPath != null) {
            System.setProperty("log4j.configurationFile", configPath);
        } else if (version != null && version.logging != null && version.logging.client != null) {
            // Set the argument directly if available, instead of log4j.configurationFile
            String log4jArg = version.logging.client.argument;
            if (log4jArg != null) {
                System.out.println("Using log4j argument: " + log4jArg);
            }
        }

        try {
            patchInstanceLwjgl();
        } catch (Throwable t) {
            System.err.println("[LWJGLFix] patch failed: " + t);
        }

        Tools.launchMinecraft(account, version);
    }
}
