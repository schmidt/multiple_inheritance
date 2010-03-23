require File.dirname(__FILE__) + '/../lib/multipleinheritance'

class A
  A_CONSTANT = "a"
  def a; "a"; end; 
  def left_first; a; end
  def own; a; end
  def block_use( &block )
    block.call + 1
  end
  def inst_plus; @a + 1; end
  def inspect; a; end
  def self.inherited( subclass ); @subclasses << subclass end
  self.instance_variable_set( :@subclasses, [] )
end

class B
  B_CONSTANT = "b"
  def b; "b"; end
  def left_first; b; end
  def own; b; end
  def inst_minus; @a - 1; end
  def to_s; b; end
  def method_missing( method_name, *arguments )
    if method_name.to_s =~ /pferde/; method_name.to_s.upcase; else; super; end
  end
  def self.inherited( subclass ); @subclasses << subclass end
  self.instance_variable_set( :@subclasses, [] )
end

class AB < MultipleInheritance[ A, B ]
  AB_DEFINED_CONSTANT = "ab"
  def init_access; @a = 3; end
  def ab; a + b; end 
  def own; ab; end 
  def access_constant_from_A; A_CONSTANT; end
  def access_constant_from_B; B_CONSTANT; end
  def access_constant_from_AB; AB_CONSTANT; end
  def self.const_missing( const_name )
    if const_name.to_s =~ /^AB_/; A_CONSTANT; else; super; end
  end
  def method_missing( method_name, *arguments )
    if method_name.to_s =~ /hase/; method_name.to_s; else; super; end
  end
  def block_call; block_use { 1 } + 1; end
end

context "A subclass of `A` and `B`" do
  specify "should answer with `[A, B]` when sended `superclasses`" do
    AB.superclasses.should == [A, B]
  end
  
  specify "should not list constants defined in its superclasses, " + 
          "when sent `constants`" do
    AB.constants.should_not include(A::A_CONSTANT)
    AB.constants.should_not include(B::B_CONSTANT)
  end

  specify "should not answer `true` to `const_defined?` for " +
          "constants defined in `A` or `B`" do
    AB.should_not be_const_defined(:A_CONSTANT)
    AB.should_not be_const_defined(:B_CONSTANT)
  end
  specify "should answer `true` to `const_defined?` for " + 
          "constants defined in it" do
    AB.should be_const_defined(:AB_DEFINED_CONSTANT)
  end

  specify "should list methods of its superclasses in " + 
          "`instance_methods( true )`" do
    AB.instance_methods.should include("a")
    AB.instance_methods.should include("b")
  end

  specify "should have the same `superclass` as another subclass of " +
          "`A` and `B`" do
    AB.superclass.should == MultipleInheritance[ A, B ]
  end
  
  specify "should have the a different `superclass` than a subclass " +
          "`B` and `A`" do
    AB.superclass.should_not == MultipleInheritance[ B, A ]
  end
end

context "The Ancestors of a subclass of `A` and `B`" do
  specify "should contain `A`, `B` and `Object`" do
    AB.ancestors.should include(A)
    AB.ancestors.should include(B)
    AB.ancestors.should include(Object)
  end
  specify "should have `A` as first element" do
    AB.ancestors.first.should == A
  end
  specify "should not include double entries" do
    AB.ancestors.size.should == AB.ancestors.uniq.size
  end
  specify "should contain `A` before `B`" do
    AB.ancestors.index(A).should < AB.ancestors.index(B)
  end
  specify "should contain `B` before `Object`" do
    AB.ancestors.index(B).should < AB.ancestors.index(Object)
  end
end

context "An instance of a subclass of `A` and `B`" do
  before do
    @instance = AB.new
  end
  
  specify "should be kind of its class" do
    @instance.should be_kind_of(AB)
  end
  specify "should be kind of its super classes" do
    @instance.should be_kind_of(A)
    @instance.should be_kind_of(B)
  end
  specify "should be kind of its super super classes" do
    @instance.should be_kind_of(Object)
  end
  
  specify "should prefer its own methods over inherited ones" do
    @instance.own.should == "ab"
  end
  specify "should be able to call inherited methods" do
    @instance.a.should == "a"
    @instance.b.should == "b"
  end
  specify "should be able to combine inherited calls" do
    @instance.ab.should == "ab"
  end
  specify "should prefer methods defined in `A` over `Object`'s" do
    @instance.inspect.should == "a"
  end
  specify "should prefer methods defined in `B` over `Object`'s" do
    @instance.to_s.should == "b"
  end
  specify "should prefer methods defined in `A` over `B`'s (left first)" do
    @instance.left_first.should == "a"
  end
  specify "should be able to use `method_missing`" do
    @instance.hasenfuss.should == "hasenfuss"
  end
  specify "should be able to use `method_missing` in one of its parents" do
    @instance.pferdefuss.should == "PFERDEFUSS"
  end

  specify "should answer `respond_to?( 'some method in A' )` with `true`" do
    @instance.respond_to?(:a).should be_true
  end
  specify "should answer `respond_to?( 'some method in B' )` with `true`" do
    @instance.respond_to?(:b).should be_true
  end
  specify "should answer `respond_to?( 'some method in Object' )` " + 
          "with `true`" do
    @instance.respond_to?(:object_id).should be_true
  end

  specify "should be able to access constants defined in " + 
          "superclasses directly" do
    @instance.access_constant_from_A.should == A::A_CONSTANT
    @instance.access_constant_from_B.should == B::B_CONSTANT
  end
  specify "should be able to use `const_missing`" do
    @instance.access_constant_from_AB.should == A::A_CONSTANT
  end
  
  specify "should list methods of its superclasses in `methods`" do
    @instance.methods.should include("a")
    @instance.methods.should include("b")
  end

  specify "should be able to use methods from `A` and `B` " + 
          "using own instance variables" do
    @instance.init_access
    @instance.inst_minus.should == 2
    @instance.inst_plus.should == 4
  end

  specify "should be able to use blocks for methods in superclasses" do
    @instance.block_call.should == 3
  end
end

context "When `A` and `B` are subclassed by a class, they" do
  specify "should be informed via `self.inherited( subclass )`" do
    A.instance_variable_get(:@subclasses).should == [ AB ]
    B.instance_variable_get(:@subclasses).should == [ AB ]
  end
end

context "When `A` or `B` are extended after a subclass of both " +
        "of them was created, the subclass" do
  before do
    @instance = AB.new
  end
  
  specify "should get a NoMethodError when trying to access the " + 
          "method before" do
    lambda { @instance.new_one }.should raise_error(NoMethodError)
  end
  
  specify "should be able to access the method correctly afterwards" do
    class B; def new_one; b; end; end
    @instance.new_one.should == @instance.b
    class A; def new_one; a; end; end
    @instance.new_one.should == @instance.a
  end
end
