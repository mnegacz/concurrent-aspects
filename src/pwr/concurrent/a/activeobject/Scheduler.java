package pwr.concurrent.a.activeobject;

import java.util.concurrent.LinkedBlockingQueue;

public class Scheduler implements Runnable {

	private LinkedBlockingQueue<MessageRequest<?>> queue = new LinkedBlockingQueue<>();

	private PoisonPill poisonPill = new PoisonPill();

	private volatile boolean running = true;

	private boolean terminateAfterMainMethod = true;

	public Scheduler(boolean terminateAfterMainMethod) {
		this.terminateAfterMainMethod = terminateAfterMainMethod;
	}

	@Override
	public void run() {
		while (running) {
			dispatch();
		}
	}

	public void dispatch() {
		try {
			MessageRequest<?> messageRequest = queue.take();
			if (!poisonPill.equals(messageRequest)) {
				if (messageRequest.guard()) {
					messageRequest.call();
				}
			}
		} catch (InterruptedException e) {
			throw new RuntimeException(e);
		}
	}

	public void enqueue(MessageRequest<?> messageRequest) {
		queue.add(messageRequest);
	}

	public void terminate() {
		running = false;
		queue.clear();
		queue.add(poisonPill);
	}

	public void terminateAfterMainMethod() {
		if (terminateAfterMainMethod) {
			terminate();
		}
	}

}
