package pwr.concurrent.a.synchronization;

import static pwr.concurrent.ObjectUtils.getObjectReferenceAsString;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.locks.ReadWriteLock;
import java.util.concurrent.locks.ReentrantReadWriteLock;

import org.aspectj.lang.JoinPoint;

import pwr.concurrent.annotation.Synchronize;

public abstract aspect SynchronizationAspect {

	public pointcut synchronizedMethod(Synchronize annotation): execution(@Synchronize * *(..)) && @annotation(annotation);

	public pointcut synchronizedStaticMethod(Synchronize annotation): execution(@Synchronize static * *(..)) && @annotation(annotation);

	private ConcurrentHashMap<String, ReadWriteLock> locks = new ConcurrentHashMap<>();

	private ConcurrentHashMap<ReadWriteLock, String> reversedLocks = new ConcurrentHashMap<>();

	private ObjectComparator comparator = new ObjectComparator();

	Object around(Synchronize annotation, Object target): synchronizedMethod(annotation) && target(target) {
		List<String> both = Arrays.asList(annotation.value());
		List<String> writes = Arrays.asList(annotation.writes());
		List<String> reads = Arrays.asList(annotation.reads());

		if (both.isEmpty() && writes.isEmpty() && reads.isEmpty()) {
			both = Collections.singletonList("this");
		}

		Set<ReadWriteLock> readLocks = new TreeSet<ReadWriteLock>(comparator);
		Set<ReadWriteLock> writeLocks = new TreeSet<ReadWriteLock>(comparator);

		fillLocks(both, readLocks, target, thisJoinPoint);
		fillLocks(reads, readLocks, target, thisJoinPoint);
		fillLocks(both, writeLocks, target, thisJoinPoint);
		fillLocks(writes, writeLocks, target, thisJoinPoint);

		try {
			applyWriteLocks(writeLocks);
			applyReadLocks(readLocks);

			return proceed(annotation, target);
		} finally {
			rejectWriteLocks(writeLocks);
			rejectReadLocks(readLocks);
		}
	}

	private void fillLocks(List<String> names, Set<ReadWriteLock> set, Object target, JoinPoint joinPoint) {
		for (String name : names) {
			String key = getKey(name, target, joinPoint);
			set.add(getLock(key));
		}
	}

	private void rejectWriteLocks(Set<ReadWriteLock> writeLocks) {
		for (ReadWriteLock lock : writeLocks) {
			lock.writeLock().unlock();
		}
	}

	private void rejectReadLocks(Set<ReadWriteLock> readLocks) {
		for (ReadWriteLock lock : readLocks) {
			lock.readLock().unlock();
		}
	}

	private void applyWriteLocks(Set<ReadWriteLock> writeLocks) {
		for (ReadWriteLock lock : writeLocks) {
			lock.writeLock().lock();
		}
	}

	private void applyReadLocks(Set<ReadWriteLock> readLocks) {
		for (ReadWriteLock lock : readLocks) {
			lock.readLock().lock();
		}
	}

	private ReadWriteLock getLock(String key) {
		ReadWriteLock lock = locks.get(key);
		if (lock == null) {
			ReadWriteLock newLock = new ReentrantReadWriteLock(true);

			lock = locks.putIfAbsent(key, newLock);

			if (lock == null) {
				lock = newLock;
			}

			reversedLocks.putIfAbsent(lock, key);
		}

		return lock;
	}

	Object around(Synchronize annotation): synchronizedStaticMethod(annotation) {
		List<String> both = Arrays.asList(annotation.value());
		List<String> writes = Arrays.asList(annotation.writes());
		List<String> reads = Arrays.asList(annotation.reads());

		if (both.isEmpty() && writes.isEmpty() && reads.isEmpty()) {
			both = Collections.singletonList("this");
		}

		Set<ReadWriteLock> readLocks = new TreeSet<ReadWriteLock>(comparator);
		Set<ReadWriteLock> writeLocks = new TreeSet<ReadWriteLock>(comparator);

		fillLocks(both, readLocks, null, thisJoinPoint);
		fillLocks(reads, readLocks, null, thisJoinPoint);
		fillLocks(both, writeLocks, null, thisJoinPoint);
		fillLocks(writes, writeLocks, null, thisJoinPoint);

		try {
			applyWriteLocks(writeLocks);
			applyReadLocks(readLocks);

			return proceed(annotation);
		} finally {
			rejectWriteLocks(writeLocks);
			rejectReadLocks(readLocks);
		}
	}

	private String getKey(String name, Object target, JoinPoint joinPoint) {
		String key = null;
		if (name.startsWith("this")) {
			if (target == null) {
				key = joinPoint.getSignature().getDeclaringTypeName();
			} else {
				key = getObjectReferenceAsString(target);
			}
			if (name.startsWith("this.")) {
				key += name.substring("this".length());
			}
		} else if ("global".equals(name)) {
			key = "global";
		} else {
			key = "custom:" + name;
		}

		return key;
	}

	public ConcurrentHashMap<String, ReadWriteLock> getLocks() {
		return locks;
	}

}
