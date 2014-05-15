package pwr.concurrent.a.synchronization;

import static java.lang.System.identityHashCode;

import java.util.Comparator;

public class ObjectComparator implements Comparator<Object> {

	@Override
	public int compare(Object firstObject, Object secondObject) {
		return identityHashCode(secondObject) - identityHashCode(firstObject);
	}

}
