package pwr.concurrent.a.asynchronous;

import net.sf.cglib.proxy.LazyLoader;

public class RecursiveTaskLazyLoader implements LazyLoader {

	private RecursiveTask<?> recursiveTask;

	public RecursiveTaskLazyLoader(RecursiveTask<?> future) {
		this.recursiveTask = future;
	}

	@Override
	public Object loadObject() throws Exception {
		recursiveTask.fork();
		return recursiveTask.join();
	}

}
