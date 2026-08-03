//
//  OSMesaShim.c — AngelAuraAmethyst
//
//  Interposes OSMesa to emulate GL_ARB_indirect_parameters.
//
//  The bundled Zink/Mesa (libOSMesa.8.dylib) does not implement
//  glMultiDrawElementsIndirectCountARB. Minecraft's LWJGL resolves every GL
//  entry point through OSMesaGetProcAddress from the library named by
//  org.lwjgl.opengl.libname. Mods like Voxy gate on that capability and
//  disable themselves when the function resolves to NULL.
//
//  This shim keeps the exact name libOSMesa.8.dylib but
//    1. forwards OSMesaGetProcAddress to the real Mesa core library
//       (libOSMesaCore.8.dylib), and
//    2. serves real implementations of the *IndirectCount entry points,
//       reading the draw count from GL_DRAW_PARAMETERS_BUFFER and delegating
//       to the plain glMultiDrawElementsIndirect.
//
//  The emulation is functionally correct: indirect commands are an array of
//  draw structures and the count value limits how many draws are executed.
#include <dlfcn.h>
#include <stddef.h>
#include <string.h>

typedef void (*GLfuncptr)(void);
typedef GLfuncptr (*OSMesaAccessor_t)(const char *name);

typedef unsigned int  GLenum;
typedef unsigned int  GLuint;
typedef int           GLint;
typedef unsigned int  GLsizei;
typedef long          GLsizeiptr;
typedef unsigned char GLubyte;

#define GL_DRAW_INDIRECT_BUFFER      0x8F2F
#define GL_DRAW_INDIRECT_BUFFER_BINDING 0x8F43
#define GL_DRAW_PARAMETERS_BUFFER_BINDING 0x8DCA
#define GL_COPY_READ_BUFFER           0x8F36

static void *s_core = NULL;
static OSMesaAccessor_t s_coreGetProc = NULL;

static void *resolveCore(void) {
    if (s_core == NULL) {
        s_core = dlopen("@rpath/libOSMesaCore.8.dylib", RTLD_NOW | RTLD_LOCAL);
        if (s_core != NULL) {
            s_coreGetProc = (OSMesaAccessor_t)dlsym(s_core, "OSMesaGetProcAddress");
        }
    }
    return (s_coreGetProc != NULL) ? (void *)1 : NULL;
}

static void *find(const char *name) {
    if (s_coreGetProc == NULL && resolveCore() == NULL) {
        return NULL;
    }
    return (void *)s_coreGetProc(name);
}

/* ----- count-draw emulation ------------------------------------------ */

static void (*pBindBuffer)(GLenum, GLuint);
static void (*pGetBufferSubData)(GLenum, GLsizeiptr, GLsizeiptr, void *);
static void (*pGetIntegeri_v)(GLenum, GLuint, GLint *);
static void (*pMultiDrawElementsIndirect)(GLenum, GLenum, const void *,
                                          GLsizei, GLsizei);

static void bindProcs(void) {
    if (pMultiDrawElementsIndirect != NULL) {
        return;
    }
    pBindBuffer                 = (void *)find("glBindBuffer");
    pGetBufferSubData           = (void *)find("glGetBufferSubData");
    pGetIntegeri_v              = (void *)find("glGetIntegeri_v");
    pMultiDrawElementsIndirect  = (void *)find("glMultiDrawElementsIndirect");
}

static void implMultiDrawElementsIndirectCount(
        GLenum mode, GLenum type, const void *indirect,
        GLsizeiptr drawCount, GLsizeiptr maxDrawCount, GLsizei stride) {
    bindProcs();
    if (pMultiDrawElementsIndirect == NULL || pGetIntegeri_v == NULL ||
        pGetBufferSubData == NULL) {
        return;
    }
    GLint paramBuf = 0;
    pGetIntegeri_v(GL_DRAW_PARAMETERS_BUFFER_BINDING, 0, &paramBuf);
    if (paramBuf == 0) {
        return;
    }
    GLsizei count = 0;
    pBindBuffer(GL_COPY_READ_BUFFER, (GLuint)paramBuf);
    pGetBufferSubData(GL_COPY_READ_BUFFER, drawCount, sizeof(count), &count);
    pBindBuffer(GL_COPY_READ_BUFFER, 0);

    if (count > maxDrawCount) {
        count = (GLsizei)maxDrawCount;
    }
    if (count > 0) {
        pMultiDrawElementsIndirect(mode, type, indirect, count, stride);
    }
}

/* ----- extension list augmentation -----------------------------------
 *
 * The bundled Zink/Mesa core does not advertise GL_ARB_compute_shader or
 * GL_ARB_indirect_parameters, so LWJGL (which walks the indexed
 * glGetStringi list on GL 3.0+ contexts) never probes the entry points that
 * Voxy gates on. We transparently append the two extension names to the
 * driver's extension list; the corresponding function pointers still come
 * from OSMesaGetProcAddress below (real Mesa for compute, emulation for the
 * count functions).
 */

#define GL_EXTENSIONS     0x1F03
#define GL_NUM_EXTENSIONS 0x821D

static const char *s_fakeExts[] = {
    "GL_ARB_compute_shader",
    "GL_ARB_indirect_parameters",
};
#define FAKE_EXT_COUNT ((int)(sizeof(s_fakeExts) / sizeof(s_fakeExts[0])))

static void (*pGetIntegervReal)(GLenum, GLint *);
static const GLubyte *(*pGetStringiReal)(GLenum, GLuint);

static void bindExtProcs(void) {
    if (pGetIntegervReal != NULL) {
        return;
    }
    pGetIntegervReal = (void *)find("glGetIntegerv");
    pGetStringiReal  = (void *)find("glGetStringi");
}

static void implGetIntegerv(GLenum pname, GLint *params) {
    bindExtProcs();
    pGetIntegervReal(pname, params);
    if (pname == GL_NUM_EXTENSIONS) {
        params[0] += FAKE_EXT_COUNT;
    }
}

static const GLubyte *implGetStringi(GLenum name, GLuint index) {
    bindExtProcs();
    GLint realCount = 0;
    pGetIntegervReal(GL_NUM_EXTENSIONS, &realCount);
    if (name == GL_EXTENSIONS && index >= (GLuint)realCount &&
        index < (GLuint)(realCount + FAKE_EXT_COUNT)) {
        return (const GLubyte *)s_fakeExts[index - (GLuint)realCount];
    }
    return pGetStringiReal(name, index);
}

/* ----- export --------------------------------------------------------- */

GLfuncptr OSMesaGetProcAddress(const char *name) {
    if (name == NULL) {
        return NULL;
    }
    if (strcmp(name, "glMultiDrawElementsIndirectCountARB") == 0 ||
        strcmp(name, "glMultiDrawElementsIndirectCount") == 0) {
        return (GLfuncptr)implMultiDrawElementsIndirectCount;
    }
    if (strcmp(name, "glGetIntegerv") == 0) {
        return (GLfuncptr)implGetIntegerv;
    }
    if (strcmp(name, "glGetStringi") == 0) {
        return (GLfuncptr)implGetStringi;
    }
    return find(name);
}