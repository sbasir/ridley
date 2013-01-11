shared_examples_for "a Ridley Resource" do |resource_klass|
  let(:connection) { double('connection', hosted?: true) }
  let(:active_connection) { double('active-connection') }
  let(:response) { double('response') }

  describe "ClassMethods" do
    subject { resource_klass }

    describe "::all" do
      it "sends a get request for the class' resource_path using the given connection" do
        response.stub(:body) { Hash.new }
        connection.should_receive(:get).with(subject.resource_path).and_return(response)
        
        subject.all(connection)
      end
    end

    describe "::find" do
      it "delegates to find!" do
        id = double('id')
        subject.should_receive(:find!).with(connection, id)

        subject.find(connection, id)
      end

      context "when the resource is not found" do
        it "returns nil" do
          pending
        end
      end
    end

    describe "::find!" do
      it "sends a get request to the given connection to the resource_path of the class for the given chef_id" do
        chef_id = "ridley_test"
        response.stub(:body) { Hash.new }
        connection.should_receive(:get).with("#{subject.resource_path}/#{chef_id}").and_return(response)

        subject.find(connection, chef_id)
      end

      context "when the resource is not found" do
        it "raises a Ridley::Errors::HTTPNotFound error" do
          pending
        end
      end
    end

    describe "::create" do
      it "sends a post request to the given connection using the includer's resource_path" do
        attrs = {
          first_name: "jamie",
          last_name: "winsor"
        }

        response.stub(:body) { attrs }
        connection.should_receive(:post).with(subject.resource_path, duck_type(:to_json)).and_return(response)

        subject.create(connection, attrs)
      end
    end

    describe "::delete" do
      it "sends a delete request to the given connection using the includer's resource_path for the given string" do
        response.stub(:body) { Hash.new }
        connection.should_receive(:delete).with("#{subject.resource_path}/ridley-test").and_return(response)

        subject.delete(connection, "ridley-test")
      end

      it "accepts an object that responds to 'chef_id'" do
        object = double("obj")
        object.stub(:chef_id) { "hello" }
        response.stub(:body) { Hash.new }
        connection.should_receive(:delete).with("#{subject.resource_path}/#{object.chef_id}").and_return(response)

        subject.delete(connection, object)
      end
    end

    describe "::delete_all" do
      it "sends a delete request for every object in the collection" do
        pending
      end
    end

    describe "::update" do
      it "sends a put request to the given connection using the includer's resource_path with the given object" do
        subject.stub(:chef_id) { :name }
        subject.attribute(:name)
        object = subject.new(name: "hello")
        response.stub(:body) { Hash.new }
        connection.should_receive(:put).with("#{subject.resource_path}/#{object.chef_id}", duck_type(:to_json)).and_return(response)

        subject.update(connection, object)
      end
    end
  end

  subject { resource_klass.new(connection) }

  describe "#save" do
    context "when the object is valid" do
      before(:each) { subject.stub(:valid?).and_return(true) }

      it "sends a create message to the implementing class" do
        updated = double('updated')
        updated.stub(:attributes).and_return(Hash.new)
        subject.class.should_receive(:create).with(connection, subject).and_return(updated)

        subject.save
      end

      context "when there is an HTTPConflict" do
        it "sends the update message to self" do
          updated = double('updated')
          updated.stub(:[]).and_return(Hash.new)
          updated.stub(:attributes).and_return(Hash.new)
          subject.class.should_receive(:create).and_raise(Ridley::Errors::HTTPConflict.new(updated))
          subject.should_receive(:update).and_return(updated)

          subject.save
        end
      end
    end

    context "when the object is invalid" do
      before(:each) { subject.stub(:valid?).and_return(false) }

      it "raises an InvalidResource error" do
        lambda {
          subject.save
        }.should raise_error(Ridley::Errors::InvalidResource)
      end
    end
  end

  describe "#update" do
    context "when the object is valid" do   
      let(:updated) do
        updated = double('updated')
        updated.stub(:[]).and_return(Hash.new)
        updated.stub(:attributes).and_return(Hash.new)
        updated
      end

      before(:each) { subject.stub(:valid?).and_return(true) }

      it "sends an update message to the implementing class" do
        subject.class.should_receive(:update).with(anything, subject).and_return(updated)
        subject.update
      end

      it "returns true" do
        subject.class.should_receive(:update).with(anything, subject).and_return(updated)
        subject.update.should eql(true)
      end
    end

    context "when the object is invalid" do
      before(:each) { subject.stub(:valid?).and_return(false) }

      it "raises an InvalidResource error" do
        lambda {
          subject.update
        }.should raise_error(Ridley::Errors::InvalidResource)
      end
    end
  end

  describe "#chef_id" do
    it "returns the value of the chef_id attribute" do
      subject.class.attribute(:name)
      subject.class.stub(:chef_id) { :name }
      subject.attributes = { name: "reset" }

      subject.chef_id.should eql("reset")
    end
  end

  describe "#reload" do
    let(:updated_subject) { double('updated_subject', attributes: { fake_attribute: "some_value" }) }

    before(:each) do
      subject.class.attribute(:fake_attribute)
      subject.class.stub(:find).with(connection, subject).and_return(updated_subject)
    end

    it "returns itself" do
      subject.reload.should eql(subject)
    end

    it "sets the attributes of self to include those of the reloaded object" do
      subject.reload

      subject.attributes.should have_key(:fake_attribute)
      subject.attributes[:fake_attribute].should eql("some_value")
    end
  end
end
