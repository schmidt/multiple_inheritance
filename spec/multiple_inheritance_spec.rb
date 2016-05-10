require File.dirname(__FILE__) + '/../lib/multiple_inheritance'

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
    expect(AB.superclasses).to eq([A, B])
  end

  specify "should not list constants defined in its superclasses, " +
          "when sent `constants`" do
    expect(AB.constants).to_not include(A::A_CONSTANT)
    expect(AB.constants).to_not include(B::B_CONSTANT)
  end

  specify "should not answer `true` to `const_defined?` for " +
          "constants defined in `A` or `B`" do
    expect(AB).to_not be_const_defined(:A_CONSTANT)
    expect(AB).to_not be_const_defined(:B_CONSTANT)
  end
  specify "should answer `true` to `const_defined?` for " +
          "constants defined in it" do
    expect(AB).to be_const_defined(:AB_DEFINED_CONSTANT)
  end

  specify "should list methods of its superclasses in " +
          "`instance_methods( true )`" do
    expect(AB.instance_methods).to include(:a)
    expect(AB.instance_methods).to include(:b)
  end

  specify "should have the same `superclass` as another subclass of " +
          "`A` and `B`" do
    expect(AB.superclass).to eq MultipleInheritance[ A, B ]
  end

  specify "should have the a different `superclass` than a subclass " +
          "`B` and `A`" do
    expect(AB.superclass).to_not eq MultipleInheritance[ B, A ]
  end
end

context "The Ancestors of a subclass of `A` and `B`" do
  specify "should contain `A`, `B` and `Object`" do
    expect(AB.ancestors).to include(A)
    expect(AB.ancestors).to include(B)
    expect(AB.ancestors).to include(Object)
  end

  specify "should have `A` as first element" do
    expect(AB.ancestors.first).to be(A)
  end
  specify "should not include double entries" do
    expect(AB.ancestors.size).to be(AB.ancestors.uniq.size)
  end
  specify "should contain `A` before `B`" do
    expect(AB.ancestors.index(A)).to be < AB.ancestors.index(B)
  end
  specify "should contain `B` before `Object`" do
    expect(AB.ancestors.index(B)).to be < AB.ancestors.index(Object)
  end
end

context "An instance of a subclass of `A` and `B`" do
  before do
    @instance = AB.new
  end

  specify "should be kind of its class" do
    expect(@instance).to be_kind_of(AB)
  end

  specify "should be kind of its super classes" do
    expect(@instance).to be_kind_of(A)
    expect(@instance).to be_kind_of(B)
  end
  specify "should be kind of its super super classes" do
    expect(@instance).to be_kind_of(Object)
  end

  specify "should prefer its own methods over inherited ones" do
    expect(@instance.own).to eq("ab")
  end

  specify "should be able to call inherited methods" do
    expect(@instance.a).to eq("a")
    expect(@instance.b).to eq("b")
  end

  specify "should be able to combine inherited calls" do
    expect(@instance.ab).to eq("ab")
  end

  specify "should prefer methods defined in `A` over `Object`'s" do
    expect(@instance.inspect).to eq("a")
  end

  specify "should prefer methods defined in `B` over `Object`'s" do
    expect(@instance.to_s).to eq("b")
  end

  specify "should prefer methods defined in `A` over `B`'s (left first)" do
    expect(@instance.left_first).to eq("a")
  end

  specify "should be able to use `method_missing`" do
    expect(@instance.hasenfuss).to eq("hasenfuss")
  end

  specify "should be able to use `method_missing` in one of its parents" do
    expect(@instance.pferdefuss).to eq("PFERDEFUSS")
  end

  specify "should answer `respond_to?( 'some method in A' )` with `true`" do
    expect(@instance.respond_to?(:a)).to eq(true)
  end

  specify "should answer `respond_to?( 'some method in B' )` with `true`" do
    expect(@instance.respond_to?(:b)).to eq(true)
  end

  specify "should answer `respond_to?( 'some method in Object' )` " +
          "with `true`" do
    expect(@instance.respond_to?(:object_id)).to eq(true)
  end

  specify "should be able to access constants defined in " +
          "superclasses directly" do
    expect(@instance.access_constant_from_A).to eq(A::A_CONSTANT)
    expect(@instance.access_constant_from_B).to eq(B::B_CONSTANT)
  end

  specify "should be able to use `const_missing`" do
    expect(@instance.access_constant_from_AB).to eq(A::A_CONSTANT)
  end

  specify "should list methods of its superclasses in `methods`" do
    expect(@instance.methods).to include(:a)
    expect(@instance.methods).to include(:b)
  end

  specify "should be able to use methods from `A` and `B` " +
          "using own instance variables" do
    @instance.init_access
    expect(@instance.inst_minus).to eq(2)
    expect(@instance.inst_plus).to eq(4)
  end

  specify "should be able to use blocks for methods in superclasses" do
    expect(@instance.block_call).to eq(3)
  end
end

context "When `A` and `B` are subclassed by a class, they" do
  specify "should be informed via `self.inherited( subclass )`" do
    expect(A.instance_variable_get(:@subclasses)).to eq([ AB ])
    expect(B.instance_variable_get(:@subclasses)).to eq([ AB ])
  end
end

context "When `A` or `B` are extended after a subclass of both " +
        "of them was created, the subclass" do
  before do
    @instance = AB.new
  end

  specify "should get a NoMethodError when trying to access the " +
          "method before" do
    expect { @instance.new_one }.to raise_error(NoMethodError)
  end

  specify "should be able to access the method correctly afterwards" do
    class B; def new_one; b; end; end
    expect(@instance.new_one).to eq(@instance.b)
    class A; def new_one; a; end; end
    expect(@instance.new_one).to eq(@instance.a)
  end
end
