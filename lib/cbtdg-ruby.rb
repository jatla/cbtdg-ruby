require 'singleton'
require 'pairwise'

class ConstraintBasedTestDataGenerator
	include Singleton
	include Pairwise

	def generateTestDataSetForModel dataModel={}, outPutFilePath
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

	def generatePairWiseData key, data
		if data.kind_of? Hash
			data.each do |k, v|
				data[k] = generatePairWiseData(k,v)
			end
			data[key] = data.values.length > 1 ? combinations(data.values) : data.values[0]
			@pairWiseData[key] = data[key]
		else
			data.to_a.each.collect{|a| [key,a]}
		end
	end

	private
	def combinations(inputs)
      raise InvalidInputData, "Minimum of 2 inputs are required to generate pairwise test set" unless valid?(inputs)
      Pairwise::IPO.new(inputs).build
    end

    def valid?(inputs)
      array_of_arrays?(inputs) &&
        inputs.length >= 2 &&
        !inputs[0].empty? && !inputs[1].empty?
    end

    def array_of_arrays?(data)
      data.reject{|datum| datum.kind_of?(Array)}.empty?
    end

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
end