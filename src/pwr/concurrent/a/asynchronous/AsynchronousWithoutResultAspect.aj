package pwr.concurrent.a.asynchronous;

import java.util.concurrent.Callable;
import java.util.concurrent.Future;

import pwr.concurrent.annotation.Asynchronous;

public abstract aspect AsynchronousWithoutResultAspect extends AsynchronousAspect {

	declare soft : Exception : callAsynchronously();

	public pointcut callAsynchronously(): call(@Asynchronous void *(..));

	void around(final Asynchronous annotation): callAsynchronously() && @annotation(annotation) {
		Callable<Object> task = new Callable<Object>() {

			@Override
			public Object call() throws Exception {
				proceed(annotation);
				return null;
			}

		};

		Future<?> future = submitTask(annotation.standalone(), task);
		registerFuture(future);
	}

}
