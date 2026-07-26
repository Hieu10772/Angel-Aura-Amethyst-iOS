package net.kdt.pojavlaunch;

import java.lang.instrument.Instrumentation;
import java.lang.reflect.Constructor;
import java.lang.reflect.Method;

public class CacioInitAgent {
    public static void premain(String args, Instrumentation inst) {
        try {
            Class<?> factoryClass = Class.forName("net.java.openjdk.cacio.ctc.CTCSurfaceManagerFactory");
            Constructor<?> ctor = factoryClass.getDeclaredConstructor();
            ctor.setAccessible(true);
            Object factory = ctor.newInstance();
            Class<?> smfClass = Class.forName("sun.java2d.SurfaceManagerFactory");
            Method setInstance = smfClass.getMethod("setInstance", smfClass);
            setInstance.invoke(null, factory);
        } catch (Exception e) {
            System.err.println("[CacioInitAgent] Skipping SurfaceManagerFactory init: " + e);
        }
    }
}
