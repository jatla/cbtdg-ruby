require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ConstraintBasedTestDataGenerator" do
	context "Domain Specific Language" do
  		it "successfully generates pairwise data for 2 level models" do

  			model = {
						supply:
						{
							instock: [true, false],
							dcxfer: [true, false]
						},
						demand:
						{
							encumbrance: [true, false],
							reservation: [true, false]
						}
					}
    		pairWiseData  = ConstraintBasedTestDataGenerator.instance.generatePairWiseData :model, model
    		puts pairWiseData
    	end
	end
end
