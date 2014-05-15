package pwr.concurrent.annotation;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface Startup {

	ThreadPool threadPool() default ThreadPool.CACHED; 
	
	int maxThreads() default 0;
	
	int coreThread() default 0;
	
	int timeout() default 0;
	
	boolean shutdownAfterMainMethod() default true;
	
}
