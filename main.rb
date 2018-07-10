require 'csv'

files = ['./Lead.csv', './Contact.csv']

class Contact
	attr_accessor :entity_type, :record
	def initialize(r, file)
		file == './Lead.csv' ? @entity_type = 'lead' : @entity_type = 'contact'
		# sf gives mailing addresses to contacts, not leads; merging them back together
		if @entity_type == 'contact'
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
		@record = r
	end

	def get_cols
		blacklist = [	
			:mailingstreet, :mailingcity, :mailingstate, :mailingpostalcode, :mailingcountry, # because of merge in init
			:mailingstatecode, :mailingcountrycode, :statecode, :countrycode, :othercountrycode, :otherstatecode,
			:billingstatecode, :billingcountrycode, :shippingstatecode, :shippingcountrycode
		]
		return @record.headers - blacklist
	end
end

contacts = Array.new
files.each do |file|
	CSV.foreach(File.path(file), headers: true, header_converters: :symbol) do |row|
		c = Contact.new(row, file)
		contacts.push(c) unless c.record[:isconverted].to_i == 1 && c.entity_type == 'lead'
	end
end

# merging in account data
CSV.foreach(File.path('./Account.csv'), headers: true, header_converters: :symbol) do |row|
	contacts.select { |c| c.record[:accountid] == row[:id] }.each do |c|
		row.each do |col,v|
			col = :accountid if	col == :id 
			col = :accounttype if col == :type
			c.record[col] = v 
		end
	end
end

lead_cols = contacts.select { |c| c.entity_type == 'lead' }.first.get_cols
contact_cols = contacts.select { |c| c.entity_type == 'contact' }.first.get_cols
columns = (lead_cols + contact_cols).uniq

# write to database table at this point
new_csv = CSV.open('./merged_data.csv', 'w', write_headers: true, headers: columns.push('entitytype'))

contacts.each do |c|
	row = Hash.new
	row['entitytype'] = c.entity_type
	columns.each do |col|
		row[col] = c.record[col] unless c.record[col].nil? || c.record[col] == '[not provided]'
	end
	new_csv << row
end


