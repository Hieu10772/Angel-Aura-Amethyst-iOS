package net.kdt.pojavlaunch;

import java.beans.Beans;
import java.io.*;
import java.lang.reflect.Field;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.util.*;
import java.util.concurrent.*;

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

        Tools.launchMinecraft(account, version);
    }
}
