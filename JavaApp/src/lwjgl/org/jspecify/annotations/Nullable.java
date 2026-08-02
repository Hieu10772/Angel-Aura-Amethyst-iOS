package org.jspecify.annotations;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Mirrors org.jspecify.annotations.Nullable (CLASS retention) so the LWJGL
 * Library shim can compile without depending on the jspecify jar that is only
 * produced mid-build by the lwgjl forks.
 */
@Documented
@Retention(RetentionPolicy.CLASS)
@Target({ElementType.TYPE_USE, ElementType.TYPE_PARAMETER, ElementType.METHOD,
         ElementType.FIELD, ElementType.PARAMETER, ElementType.LOCAL_VARIABLE})
public @interface Nullable {
}
