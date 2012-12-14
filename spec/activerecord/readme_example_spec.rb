# -*- encoding : utf-8 -*-
require "./spec/active_record_helper"
require './spec/spec_helper'
require 'examples/readme_example'



describe "readme example" do
  let(:mom){ Mom.create(:kid => Kid.create) }
  let(:kid){ mom.kid }
  let(:default_slices) {8}
  describe "when momma bakes a cake" do
    let(:cake) { mom.cakes.create(:slices => default_slices) }
    it "should have a slice eaten by the kid" do
      cake
      mom.cakes.last.reload.slices.should == Cake.default_slices - 1
      mom.kid.reload.slices.should == 1
    end
    it "should not tell the kid he's fat" do
      kid.should_not_receive(:cry!)
      kid.should_not_receive(:throw_slices_away!)
    end
    describe "and the cake is fully eaten by the kid" do
      let(:default_slices) {1}
      it "should bust kids ass" do
        LOGGER.should_receive(:info).with("Slam!!")
        cake
      end
    end
    describe "and the kid has plenty of slices" do
      before(:each) do
        kid.update_column(:slices, 20)
      end
      it "should tell kid he's fat" do
        LOGGER.should_receive(:info).with("Hey Fatty, BEEFCAKE!!!!!")
        LOGGER.should_receive(:info).with(":'(")
        cake
        kid.reload.slices.should == 0
      end
    end
  end



end
