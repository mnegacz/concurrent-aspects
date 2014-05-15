package pwr.concurrent.a.asynchronous;

import java.util.concurrent.Callable;
import java.util.concurrent.Future;

import pwr.concurrent.annotation.Asynchronous;

public abstract aspect AsynchronousWithResultAspect extends AsynchronousAspect {

	public pointcut callAsynchronously(): call(@Asynchronous Result *(..));

	Object around(final Asynchronous annotation): callAsynchronously() && @annotation(annotation) {
		boolean standalone = annotation.standalone();
		Callable<Object> task = new Callable<Object>() {

			@Override
			public Object call() throws Exception {
				return proceed(annotation);
			}

		};

		Future<?> future = submitTask(standalone, task);
		registerFuture(future);
		return new Result<>(future);
	}

}
