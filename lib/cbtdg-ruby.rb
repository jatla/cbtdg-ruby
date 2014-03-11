require 'singleton'
require 'pairwise'
require 'pp'

# Top level class used by cbtdg.rb commandline tool to traverse through
# hierarchical data models and generate test data using pairwise methodology.

class ConstraintBasedTestDataGenerator
	include Singleton
	include Pairwise

# Top level method to generate test data and write it to the specified output file.
#
# ==== Attributes
#
# * +dataModel+ - The dataModel(which is a Hash) for which test data has to be generated.
# * +outPutFilePath+ - Path of the file to which generated test data needs to be written to.

	def generate(dataModelWithConstraints, outPutFilePath=nil)
		@dataModel = Marshal.load(Marshal.dump(dataModelWithConstraints[:model]))
		@constraints = dataModelWithConstraints[:constraints]
		testTuples = generateTestDataForModel(@dataModel)
		if !outPutFilePath.nil?
			outputFile = File.open(outPutFilePath, "w")
			begin
				writeToFile(outputFile, dataModelWithConstraints[:model], testTuples)
			rescue IOError => e
				puts e
			ensure
	  			outputFile.close unless outputFile.nil?
			end
		end
		testTuples
	end

# Method to generate test data for a given model using pairwise methodology
#
# ==== Attributes
#
# * +dataModel+ - The dataModel(which is a Hash) for which test data has to be generated.

	def generateTestDataForModel(dataModel)
		@pairWiseData = {}
		generatePairWiseData(:model, dataModel)
		testTuples = []
		@pairWiseData[:model].each do |p|
			testTuples << convertArrayToHash(p)
		end
		testTuples
	end

private

# Helper method that generates pairwise data for each sub-structure in the model.
#
# ==== Attributes
#
# * +key+ - The key of the sub-structure in original model.
# * +data+ - Value for the above key in original model.

	def generatePairWiseData(key, data)
		if data.kind_of? Hash
			data.each do |k, v|
				data[k] = generatePairWiseData(k,v)
			end
			testData = data.values.length > 1 ? combinations(data.values) : data.values[0]
			@pairWiseData[key] = applyConstraints(key, testData)
		else
			data.to_a.each.collect{|a| [key,a]}
		end
	end

# Helper method that applies constraints for each sub-structure.
#
# ==== Attributes
#
# * +key+ - Key of the sub-structure whose constraints are to be applied.
# * +testData+ - Generated test data for the sub-structure.

	def applyConstraints(key, data)
		if (!@constraints.nil? && !@constraints[key].nil?)
			@constraints[key].each do |c|
				data.collect!{|d| c.call(convertArrayToHash(d))}.compact!
			end
		end
		data
	end

# Helper method that writes generated pairwise data to given file.
#
# ==== Attributes
#
# * +outPutFilePath+ - Path of the file to which generated test data needs to be written to.
# * +dataModel+ - Original data model for which test data is generated.
# * +testTuples+ - Test data generated for the given model.

    def writeToFile(outputFile, dataModel, testTuples)
		outputFile.write("MODEL:\n\n")
    	PP.pp(dataModel, outputFile)
		#outputFile.write(dataModel.to_s)
		outputFile.write("\n------------------------\n\n")
		outputFile.write("GENERATED TEST DATA:\n\n")
		testTuples.each_index do |i|
			outputFile.write("#{i+1}. #{testTuples[i].to_s}\n")
		end
		outputFile.write("------------------------\n\n")

		# outputFile.write("INTERMEDIATE DATA:\n\n")

		# @pairWiseData.each do |k, v|
		# 	outputFile.write("#{k} : \n")
		# 	PP.pp(v, outputFile)
		# 	outputFile.write("\n")
		# 	#outputFile.write("#{k} : \n #{v.to_s}\n")
		# end
		# outputFile.write("------------------------\n\n")
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

    def convertArrayToHash(array)
		# The array should be converted using either 
		# Hash[p] or p.to_h. Need more work on this
		hash = {}
		array.flatten.each_slice(2) do |e|
			hash[e[0]] = e[1]
		end
		hash
    end
end