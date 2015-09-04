require 'rails_helper'

module Ddr::Batch

  describe BatchesController, type: :routing, batch: true do

    routes { Engine.routes }

    describe "RESTful routes" do
      it "should have an index route" do
        @route = {controller: 'ddr/batch/batches', action: 'index'}
        expect(get: '/batches').to route_to(@route)
      end
      it "should have a show route" do
        @route = {controller: 'ddr/batch/batches', action: 'show', id: "1"}
        expect(:get => '/batches/1').to route_to(@route)
      end
      it "should have a destroy route" do
        @route = {controller: 'ddr/batch/batches', action: 'destroy', id: "1"}
        expect(:delete => '/batches/1').to route_to(@route)
      end
    end
    describe "non-RESTful routes" do
      it "should have a route for validating a batch" do
        @route = {controller: 'ddr/batch/batches', action: 'validate', id: '1'}
        expect(:get => 'batches/1/validate').to route_to(@route)
      end
      it "should have a route for processing a batch" do
        @route = {controller: 'ddr/batch/batches', action: 'procezz', id: '1'}
        expect(:get => 'batches/1/procezz').to route_to(@route)
      end
    end
  end

end