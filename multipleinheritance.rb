#   Multiple Inheritance
#
#   Copyright (C) 2005 Maurice Codik - maurice.codik@gmail.com
#   Copyright (C) 2007 Gregor Schmidt - gregor@schmidtwisser.de 
#
#   Permission is hereby granted, free of charge, to any person obtaining a copy
#   of this software and associated documentation files (the "Software"), to 
#   deal in the Software without restriction, including without limitation the 
#   rights to use, copy, modify, merge, publish, distribute, sublicense, and/or 
#   sell copies of the Software, and to permit persons to whom the Software is 
#   furnished to do so, subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be included in 
#   all copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
#   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
#   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
#   IN THE SOFTWARE.

#   Changelog
#   0.1.3
#    - added support for blocks 
#   0.1.2
#    - added naive support for instance variables
#   0.1.1
#    - moved Multiple to module Kernel - so it's included in the class hierarchy

module Kernel
  def Multiple( *superklasses )
    c = Class.new do

      def initialize( *arguments, &block )
        # ugly, but retrieves the value saved below
        myparents = self.class.superclass.instance_variable_get(:@parents)      

        # initialize each parent class
        @parents = []
        myparents.each do |klass|
        # note: the constructors better be compatible, otherwise this will error
          @parents << klass.new( *arguments, &block )
        end
      end

      def parent_class_for( method_name )
        self.class.ancestors.find do | ancestor |
          ancestor.instance_methods( false ).include?( method_name.to_s )
        end
      end

      def parent_instance_for( method_name, if_nil = nil )
        parent_class = parent_class_for( method_name )
        @parents.find( if_nil ) do | parent |
          parent.kind_of?( parent_class )
        end
      end
        
      def copy_instance_variables( from, to )
        from.instance_variables.each do | inst_var |
          to.instance_variable_set( inst_var, 
              from.instance_variable_get( inst_var ) )
        end
      end
      
      def copy_instance_variables_to_parent( parent_instance )
        copy_instance_variables( self, parent_instance )
      end

      def copy_instance_variables_from_parent( parent_instance )
        copy_instance_variables( parent_instance, self )
      end

      def parent_call( parent_instance, &block )
        copy_instance_variables_to_parent( parent_instance )
        return_value = block.call
        copy_instance_variables_from_parent( parent_instance )
        return_value
      end
      
      def send( method_name, *arguments, &block )
        if parent_instance = parent_instance_for( method_name ) 
          parent_call( parent_instance ) do 
            parent_instance.send( method_name, *arguments, &block )
          end
        else
          self.method_missing( method_name, *arguments, &block )
        end
      end

      def method_missing( method_name, *arguments, &block )
        parent_instance = parent_for( :method_missing, @parents.first )
        parent_call( parent_instance ) do 
          parent_instance.method_missing( method_name , *arguments, &block )
        end
      end

      def respond_to?( meth )
        if @parents.find { |p| p.respond_to? meth } 
          true
        else
          super
        end
      end

      def kind_of?( klass )
        klass == self.class or self.class.ancestors.include? klass 
      end

      def self.to_s
        if self.instance_variable_get( :@parents )
          "MultipleInheritance [" + self.superclasses.join( ", " ) + "]"
        else
          super
        end
      end
      
      def self.superclasses
        self.instance_variable_get( :@parents ) or 
        self.superclass.instance_variable_get( :@parents )
      end
      
      def self.ancestors
        superclasses.collect { | klass |
          klass.ancestors
        }.flatten.reverse.uniq.reverse
      end

      def self.inherited( subklass )
        superclasses.each do | klass | 
          klass.class_eval { inherited( subklass ) }
        end
        super
      end

      def self.parent_class_for( method_name )
        self.ancestors.find do | ancestor |
          ancestor.public_methods( false ).include?( method_name.to_s ) or
          ancestor.protected_methods( false ).include?( method_name.to_s ) or
          ancestor.private_methods( false ).include?( method_name.to_s )
        end
      end
      
      def self.const_missing( constant_name )
        if right_klass = superclasses.find do | superklass |
            superklass.constants.include?( constant_name.to_s )
          end
          right_klass.const_get( constant_name )
        else
          self.parent_class_for( :const_missing ).const_missing( constant_name )
        end
      end
    end
    
    # we need to save the parent classes so they can be initialized when 
    # our class is initialized
    c.instance_variable_set( :@parents, superklasses )

    # register all implemented calls up to Object in this class to use send
    # FIXME: had to use class_eval with string - otherwise no blocks possible
    # TODO: what should happen, if some of them are defined lateron
    c.ancestors.each do | ancestor |
      ancestor.instance_methods( false ).each do | method_name |
        c.class_eval %Q{
          def #{method_name}( *arguments, &block )
            send( :#{method_name}, *arguments, &block )
          end
        }
      end
      break if ancestor == Object
    end
    
    return c
  end
end

if __FILE__ == $0
  require "test/unit"

  class A
    def a; "a"; end
  end
  class B 
    def b; "b"; end
  end
  class C 
    def c; "c"; end
  end
  class Union < Multiple(A, B, C)
    def foo; "foo"; end
  end

  class Tests < Test::Unit::TestCase

    def setup
      @t = Union.new
    end

    def test_respond
      assert(@t.respond_to?(:a), "responds to a")
      assert(@t.respond_to?(:b), "responds to b")
      assert(@t.respond_to?(:c), "responds to c")
      assert(@t.respond_to?(:foo), "responds to foo")
    end

    def test_calls
      assert_equal(@t.a, "a", "returns a")
      assert_equal(@t.b, "b", "returns b")
      assert_equal(@t.c, "c", "returns c")
      assert_equal(@t.foo, "foo", "returns foo")
    end
  end
end
