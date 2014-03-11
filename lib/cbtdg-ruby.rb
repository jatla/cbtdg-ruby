require 'singleton'
require 'pairwise'

# Top level class used by cbtdg.rb commandline tool to traverse through
# hierarchical data models and generate test data using pairwise methodology.

class ConstraintBasedTestDataGenerator
	include Singleton
	include Pairwise

# Top level method to generate test data for a given model using pairwise methodology
# and write it to the specified output file.
#
# ==== Attributes
#
# * +dataModel+ - The dataModel(which is a Hash) for which test data has to be generated.
# * +outPutFilePath+ - Path of the file to which generated test data needs to be written to.

	def generateTestDataForModel(dataModel, outPutFilePath)
		copyOfModel = Marshal.load(Marshal.dump(dataModel))
		@pairWiseData = {}
		generatePairWiseData(:model, copyOfModel[:model])
		testTuples = []
		@pairWiseData[:model].each do |p|
			tupleHash = {}
			tupleArray = p.flatten
			index = 0
			while(index < tupleArray.length)
				tupleHash[tupleArray[index]] = tupleArray[index+1]
				index += 2
			end
			testTuples << tupleHash
		end

		writeToFile(outPutFilePath, dataModel, testTuples)
	end

private

# Helper method that generates pairwise data for each sub-structure in the model.
#
# ==== Attributes
#
# * +key+ - The key of the sub-structure in original model.
# * +data+ - Value for the above key in original model.

	def generatePairWiseData key, value
		if value.kind_of? Hash
			constraints = value[:constraints]

			data = value.reject{|k, v| k.eql? :constraints}
			data.each do |k, v|
				data[k] = generatePairWiseData(k,v)
			end
			testData = data.values.length > 1 ? combinations(data.values) : data.values[0]
			testData = applyConstraints(constraints, testData)
			@pairWiseData[key] = testData
		else
			value.to_a.each.collect{|a| [key,a]}
		end
	end

# Helper method that applies constraints for each sub-structure.
#
# ==== Attributes
#
# * +constraints+ - List of constraints that need to be applied on generated test data.
# * +testData+ - Generated test data.

	def applyConstraints constraints, testData
		# TODO
		testData
	end

# Helper method that writes generated pairwise data to given file.
#
# ==== Attributes
#
# * +outPutFilePath+ - Path of the file to which generated test data needs to be written to.
# * +dataModel+ - Original data model for which test data is generated.
# * +testTuples+ - Test data generated for the given model.

    def writeToFile outPutFilePath, dataModel, testTuples
    	begin
  			File.open(outPutFilePath, "w") do |file|
	  			file.write("MODEL:\n")
	  			file.write(dataModel.to_s)
	  			file.write("\n------------------------\n\n")
	  			file.write("GENERATED TEST DATA:\n")
	  			testTuples.each_index do |i|
	  				file.write("#{i}. #{testTuples[i].to_s}\n")
	  			end
				file.write("------------------------\n\n")

				file.write("INTERMEDIATE DATA:\n")

	  			@pairWiseData.each do |k, v|
	  				file.write("#{k} : \n #{v.to_s}\n")
	  			end
				file.write("------------------------\n\n")
			end
		rescue IOError => e
  			puts e
		end
    end

    # This is copied from the pairwise gem as the array of arrays
    # generated from the model were being wrapped into another top level array by
    # combinations method in Pairwise module.

	def combinations(inputs)
      raise InvalidInputData, "Minimum of 2 inputs are required to generate pairwise test set" unless valid?(inputs)
      Pairwise::IPO.new(inputs).build
    end

    # This is copied from Pairwise module to support combinations method

    def valid?(inputs)
      array_of_arrays?(inputs) &&
        inputs.length >= 2 &&
        !inputs[0].empty? && !inputs[1].empty?
    end

	# This is copied from Pairwise module to support valid? method

    def array_of_arrays?(data)
      data.reject{|datum| datum.kind_of?(Array)}.empty?
    end

end