package pwr.concurrent.annotation;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface Synchronize {

	String[] value() default {};

	String[] reads() default {};
	
	String[] writes() default {};
	
}
