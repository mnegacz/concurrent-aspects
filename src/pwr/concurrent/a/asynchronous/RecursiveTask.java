package pwr.concurrent.a.asynchronous;

public abstract class RecursiveTask<V> extends java.util.concurrent.RecursiveTask<V> {
	private static final long serialVersionUID = 1L;

	public abstract V compute();

}
