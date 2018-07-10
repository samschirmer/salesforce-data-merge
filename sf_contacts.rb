require 'csv'

class Contact
	attr_accessor :type, :record

	def initialize(r, file)
		file == './leads.csv' ? @type = 'lead' : @type = 'contact'
		# sf gives mailing addresses to contacts, not leads; merging them back together
		if @type == 'contact'
			if r[:street].nil? and r[:city].nil? and r[:state].nil? and r[:postalcode].nil?
				r[:street] = r[:mailingstreet]
				r[:city] = r[:mailingcity]	
				r[:state] = r[:mailingstate]	
				r[:postalcode] = r[:mailingpostalcode]	
				r[:country] = r[:mailingcountry]	
			else
				r[:otherstreet] = r[:mailingstreet]
				r[:othercity] = r[:mailingcity]	
				r[:otherstate] = r[:mailingstate]	
				r[:otherpostalcode] = r[:mailingpostalcode]	
				r[:othercountry] = r[:mailingcountry]	
			end
		end
		@row = r
		@record = @row.to_h
	end

	def get_cols
		blacklist = [	
			:mailingstreet, :mailingcity, :mailingstate, :mailingpostalcode, :mailingcountry, # because of merge in init
			:mailingstatecode, :mailingcountrycode, :statecode, :countrycode, :othercountrycode, :otherstatecode
		]
		return @row.headers - blacklist
	end
end

files = ['./leads.csv', './contacts.csv']
contacts = Array.new
files.each do |file|
	CSV.foreach(File.path(file), headers: true, header_converters: :symbol) do |row|
		c = Contact.new(row, file)
		contacts.push(c)
	end
end

lead_cols = contacts.select { |c| c.type == 'lead' }.first.get_cols
contact_cols = contacts.select { |c| c.type == 'contact' }.first.get_cols
columns = (lead_cols + contact_cols).uniq

# write to database table at this point
new_csv = CSV.open('./merged_data.csv', 'w', write_headers: true, headers: columns.push('type'))

contacts.each do |c|
	row = Hash.new
	row['type'] = c.type
	columns.each do |col|
		row[col] = c.record[col] unless c.record[col].nil? || c.record[col] == '[not provided]'
	end
	new_csv << row
end
