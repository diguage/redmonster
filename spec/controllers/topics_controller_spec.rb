require 'spec_helper'

describe TopicsController do
  before(:each) do
    @topic = create(:topic)
    @node = create(:node)
    @topic_params = {:title => 'hi', :content => 'Rails is cool', :node_ids => [@node.id]}
  end

  it "should show topic" do
    get :show, :id => @topic.id
    should respond_with(:success)
    should assign_to(:topic)
    should assign_to(:title)
    should assign_to(:total_comments)
    should assign_to(:total_pages)
    should assign_to(:current_page)
    should assign_to(:comments)
    should assign_to(:new_comment)
    should assign_to(:total_bookmarks)

    should assign_to(:canonical_path)
    should assign_to(:seo_description)
  end

  it "should output feed" do
    get :index, :format => :atom
    should respond_with(:success)
  end

  it "should show topic in mobile version" do
    get :show, :id => @topic.id, :format => :mobile
    should respond_with(:success)
  end

  it "should show all topics" do
    get :index
    should respond_with(:success)
    should assign_to(:topics)
    should assign_to(:title)
    should assign_to(:seo_description)
  end

  it "should show atom feed" do
    get :index, :format => :atom
    should respond_with(:success)
    should assign_to(:feed_items)
  end

  context "anonymous users" do
    it "should redirect when trying to create topic" do
      expect {
        post :create, :topic => @topic_params
      }.to_not change{Topic.count}.by(1)
      should respond_with(:redirect)
    end

    it "should redirect when trying to edit topic" do
      get :edit, :id => @topic.id
      should respond_with(:redirect)
      should_not assign_to(:topic)
    end

    it "should redirect when visit topic creation form" do
      get :new
      should respond_with(:redirect)
      should_not assign_to(:topic)
    end

    it "should redirect when updating topic" do
      post :update, :id => @topic.id, :topic => @topic_params
      should respond_with(:redirect)
      should_not assign_to(:topic)
    end

    it "should not move topic" do
      get :move, :id => @topic.id, :format => :js
      should respond_with(:unauthorized)
    end

    it "should redirect when trying to delete topic" do
      delete :destroy, :id => @topic.id
      should respond_with(:redirect)
      should_not assign_to(:topic)
    end
  end

  context "authenticated users" do
    login_user(:devin)
    before(:each) do
      @current_user = User.find_by_nickname(:devin)
      @node = create(:node)
      @my_topic = create(:topic, :user => @current_user)
    end

    it "can create topic" do
      expect {
        post :create, :topic => @topic_params
      }.to change{Topic.count}.by(1)
      should respond_with(:redirect)
    end

    it "can create topic without content" do
      expect {
        post :create, :topic => {:title => 'hi', :node_ids => [@node.id]}
      }.to change{Topic.count}.by(1)
      should respond_with(:redirect)
    end

    it "can edit topic" do
      get :edit, :id => @my_topic.id
      should respond_with(:success)
      should assign_to(:topic)
    end

    it "should display topic creation form in mobile version" do
      get :new, :format => :mobile
      should respond_with(:success)
    end

    it "can only edit own topics" do
      nana = create(:user)
      others_topic = create(:topic, :user => nana)
      get :edit, :id => others_topic.id
      should respond_with(:redirect)
      should assign_to(:topic)
    end

    it "can't update others topic" do
      post :update, :id => @topic.id, :topic => @topic_params
      should respond_with(:redirect)
      should assign_to(:topic)
      should set_the_flash
    end

    it "can't update locked topic" do
      locked_topic = create(:locked_topic, :user => @current_user)

      post :update, :id => locked_topic.id, :topic => @topic_params
      should respond_with(:redirect)
      should redirect_to(root_path)
      should set_the_flash
      should assign_to(:topic)
      assigns(:topic).title.should_not == @topic_params[:title]
    end

    it "can update created topics when it's not locked" do
      post :update, :id => @my_topic.id, :topic => @topic_params
      should assign_to(:topic)
      should respond_with(:redirect)
      should redirect_to(t_path(@my_topic.id))
      should_not set_the_flash
    end

    it "should redirect when trying to delete topic" do
      expect {
        delete :destroy, :id => @topic.id
      }.to_not change{Topic.count}.by(-1)
      should respond_with(:redirect)
      should redirect_to(root_path)
    end

    it "should redirect when trying to toggle comments closed status of topic" do
      put :toggle_comments_closed, :topic_id => @topic.id
      should_not assign_to(:topic)
      should redirect_to(root_path)
      flash[:notice].should_not be_empty
    end

    it "should redirect when trying to toggle sticky status of topic" do
      put :toggle_sticky, :topic_id => @topic.id
      should_not assign_to(:topic)
      should redirect_to(root_path)
      flash[:notice].should_not be_empty
    end
  end

  context "admins" do
    login_admin :devin
    before(:each) do
      @current_user = User.find_by_nickname(:devin)
      @locked_topic = create(:locked_topic)
    end

    it "can edit locked topics" do
      get :edit, :id => @locked_topic.id
      should respond_with(:success)
      should assign_to(:topic)
    end

    it "can update locked topics" do
      post :update, :id => @locked_topic.id, :topic => @topic_params
      should assign_to(:topic)
      should respond_with(:redirect)
      should redirect_to(t_path(@locked_topic.id))
      should_not set_the_flash
    end

    it "should move topics" do
      get :move, :id => @topic.id, :format => :js
      should respond_with(:success)
    end

    it "should delete topic" do
      expect {
        delete :destroy, :id => @topic.id
      }.to change{Topic.count}.by(-1)
    end

    it "can toggle comments_closed status of topic" do
      put :toggle_comments_closed, :topic_id => @topic.id
      assigns(:topic).comments_closed.should be_true
      should redirect_to(t_path(@topic.id))
      should_not set_the_flash
    end

    it "can toggle sticky status of topic" do
      put :toggle_sticky, :topic_id => @topic.id
      assigns(:topic).sticky.should be_true
      should redirect_to(t_path(@topic.id))
      should_not set_the_flash
    end
  end
end

