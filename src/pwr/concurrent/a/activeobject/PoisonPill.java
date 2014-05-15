package pwr.concurrent.a.activeobject;

public class PoisonPill extends MessageRequest<Void> {

	public PoisonPill() {
		super(null);
	}

	@Override
	public boolean guard() {
		return false;
	}

	@Override
	public void call() {
	}

}
