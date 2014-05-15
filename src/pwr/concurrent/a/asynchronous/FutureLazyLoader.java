package pwr.concurrent.a.asynchronous;

import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;

import net.sf.cglib.proxy.LazyLoader;

public class FutureLazyLoader implements LazyLoader {

	private Future<?> future;

	public FutureLazyLoader(Future<?> future) {
		this.future = future;
	}

	@Override
	public Object loadObject() throws Exception {
		try {
			return future.get();
		} catch (ExecutionException e) {
			throw (Exception) e.getCause();
		}
	}

}
