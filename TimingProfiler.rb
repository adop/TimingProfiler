#/usr/bin/ruby
module TimingProfiler
  @@timingPerMethod=Hash.new #timingPerMethod[method]=timing_cost
  @@callTimesPerMethod=Hash.new #callTimesPerMethod[method]=call_times
  def self.included(base)
    base.extend ClassMethods

    base.instance_eval do
      def singleton_method_added(name)

        return if name.to_s =~/^custom_/
        return if name.to_s =~/^original_/
        return if name.to_s =~/^method_added/
        return if name.to_s =~/^singleton_method_added/

        overwrite_class_method(name)
      end

      def method_added(name)
        return if name.to_s =~/^singleton_method_added/
        return if name.to_s =~/^custom_/
        return if name.to_s =~/^original_/
        overwrite_method(name)
      end

    end
  end

  def readCalculator
    @@timingPerMethod
  end

  def storeStat(t_method,timing)

    @@timingPerMethod[t_method]||=0
    @@timingPerMethod[t_method]+=timing
    @@callTimesPerMethod[t_method]||=0
    @@callTimesPerMethod[t_method]+=1
  end

  #output timing statistics
  def outputStat
    sorted_timing_pair=@@timingPerMethod.sort_by{|k,v| v}
    puts "Total timing cost, calling times:"
    sorted_timing_pair.each{|class_method,timing_cost|
      puts "#{class_method}: #{timing_cost} s, #{@@callTimesPerMethod[class_method]}"
    }
    

  end

  module ClassMethods
    def overwrite_method(t_method)
      custom_method=("custom_"+t_method.to_s).to_sym
      original_method=("original_"+t_method.to_s).to_sym
      class_eval do
        unless method_defined?(custom_method.to_sym)
          define_method(custom_method.to_sym) do |*args|
            timing_start=Time.now
            return_thing=send original_method,*args
            timing_end=Time.now
            method_name=(self.class.to_s+"#"+t_method.to_s).to_sym
            storeStat method_name,(timing_end-timing_start)
            return_thing
          end
        end

        if instance_method(t_method.to_sym) != instance_method(custom_method)
          alias_method original_method, t_method.to_sym
          alias_method t_method.to_sym, custom_method
        end

      end
    end

    def overwrite_class_method(t_method)

      custom_method=("custom_"+t_method.to_s).to_sym
      original_method=("original_"+t_method.to_s).to_sym
      class_eval do
        class_name=self.to_s
        singleton= class<<self
          self
        end
        unless singleton.method_defined?(custom_method.to_sym)

          singleton.send :define_method, custom_method.to_sym, lambda {|*args|
            timing_start=Time.now
            return_thing=send original_method,*args
            timing_end=Time.now
            method_name=(class_name+"::"+t_method.to_s).to_sym
            Calculator.storeStat method_name,(timing_end-timing_start)
            return_thing
          }
        end

        if method(t_method.to_sym) != method(custom_method)
          singleton.send :alias_method, original_method, t_method.to_sym
          singleton.send :alias_method, t_method.to_sym, custom_method
        end

      end #End of class_eval
    end #End of def overwrite_class_method
  end #End of def Module ClassMethods
end

class Calculator
  extend TimingProfiler

end