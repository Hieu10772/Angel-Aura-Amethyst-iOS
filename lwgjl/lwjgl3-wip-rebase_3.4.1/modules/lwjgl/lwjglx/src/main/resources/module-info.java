/*
 * Copyright LWJGL. All rights reserved.
 * License terms: https://www.lwjgl.org/license
 */
module org.lwjgl.lwjglx {
    requires transitive org.lwjgl;

    requires static org.lwjgl.glfw;
    requires static org.lwjgl.openal;
    requires static org.lwjgl.opengl;

    exports org.lwjgl;
    //exports org.lwjgl.input;
    //exports org.lwjgl.openal;
    //exports org.lwjgl.opengl;
    //exports org.lwjgl.util;
}
