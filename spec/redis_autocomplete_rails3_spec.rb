require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe RedisAutocompleteRails3 do
  context "when a class has an autocomplete attribute declared" do
    before do
      class ::Tag < ActiveRecord::Base
        redis_autocomplete :name
      end
      ::Tag.destroy_all
    end

    it "should have suggest_field methods added" do
      ::Tag.should respond_to(:suggest_name)
    end

    context "on object creation" do
      it "should add the declared field value to the autocommplete results" do
        ::Tag.create!(:name => 'test')
        ::Tag.redis_autocompleter.redis.zrange(::Tag.redis_autocomplete_fields[:name], 0, 100).should include('test+')
        ::Tag.redis_autocompleter.suggest('t', 10, ::Tag.redis_autocomplete_fields[:name]).should include('test')
        ::Tag.suggest_name('t').should include('test')
      end
    end
    context "on object update" do
      it "should remove the old field value"
      it "should add the new field value"
    end
    context "on object delete" do
      it "should remove the old field value"
    end
  end
end
