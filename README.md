TimingProfiler
==============

A plug and play Ruby Timing Profiler 

If you want to know the time cost of methods in a class A, just include this module. All the methods in class A will 
be wrapped with timing stamps.

 class A
	include TimingProfiler
	...
 end
 
 Then after program executing, call A.new.outputStat will print the timing cost for each method in class A and A's instance.