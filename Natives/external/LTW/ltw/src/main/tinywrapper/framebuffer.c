#include "proc.h"
#include "egl.h"

#ifdef __cplusplus
extern "C" {
#endif

void glClearBufferiv(GLenum buffer, GLint drawbuffer, const GLint *value) {
    es3_functions.glClearBufferiv(buffer, drawbuffer, value);
}

void glClearBufferuiv(GLenum buffer, GLint drawbuffer, const GLuint *value) {
    es3_functions.glClearBufferuiv(buffer, drawbuffer, value);
}

void glClearBufferfv(GLenum buffer, GLint drawbuffer, const GLfloat *value) {
    es3_functions.glClearBufferfv(buffer, drawbuffer, value);
}

void glDrawBuffer(GLenum buf) {
    es3_functions.glDrawBuffers(1, &buf);
}

void glDrawBuffers(GLsizei n, const GLenum *buffers) {
    es3_functions.glDrawBuffers(n, buffers);
}

GLenum glCheckFramebufferStatus(GLenum target) {
    return es3_functions.glCheckFramebufferStatus(target);
}

void glFramebufferTexture2D(GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level) {
    es3_functions.glFramebufferTexture2D(target, attachment, textarget, texture, level);
}

void glFramebufferTextureLayer(GLenum target, GLenum attachment, GLuint texture, GLint level, GLint layer) {
    es3_functions.glFramebufferTextureLayer(target, attachment, texture, level, layer);
}

void glFramebufferRenderbuffer(GLenum target, GLenum attachment, GLenum rtarget, GLuint renderbuffer) {
    es3_functions.glFramebufferRenderbuffer(target, attachment, rtarget, renderbuffer);
}

void glGetFramebufferAttachmentParameteriv(GLenum target, GLenum attachment, GLenum pname, GLint *params) {
    es3_functions.glGetFramebufferAttachmentParameteriv(target, attachment, pname, params);
}

void glGenFramebuffers(GLsizei n, GLuint *framebuffers) {
    es3_functions.glGenFramebuffers(n, framebuffers);
}

void glDeleteFramebuffers(GLsizei n, const GLuint *framebuffers) {
    es3_functions.glDeleteFramebuffers(n, framebuffers);
}

void glBindFramebuffer(GLenum target, GLuint framebuffer) {
    es3_functions.glBindFramebuffer(target, framebuffer);
}

#ifdef __cplusplus
}
#endif
