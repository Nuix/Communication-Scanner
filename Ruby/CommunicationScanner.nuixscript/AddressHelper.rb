# Helper methods for working with item emails addresses
class AddressHelper
	# Regular expression for extracting domain from email address
	@domain_regex = /^.*@([^@]+)$/

	# Given 1 or more items, will generate a list of distinct email addresses
	# on those items, yields a progress count to the provided block
	def self.get_distinct_addresses(items,&block)
		addresses = {}
		Array(items).each_with_index do |item,item_index|
			if block_given?
				block.call(item_index)
			end
			communication = item.getCommunication
			next if communication.nil?
			communication.getFrom.each{|address|addresses[address.getAddress.downcase] = true}
			communication.getTo.each{|address|addresses[address.getAddress.downcase] = true}
			communication.getCc.each{|address|addresses[address.getAddress.downcase] = true}
			communication.getBcc.each{|address|addresses[address.getAddress.downcase] = true}
		end
		return addresses
	end

	# Given 1 or more Address objects, returns a distinct list of domains,
	# yields progress count to the provided block
	def self.get_distinct_domains(addresses,&block)
		domains = {}
		Array(addresses).each_with_index do |address,address_index|
			begin
				if block_given?
					block.call(address_index)
				end
				domain = get_address_domain(address)
				next if domain.nil? || domain.strip.empty?
				domains[domain] = true
			rescue Exception => exc
				puts exc.message
				puts exc.backtrace
			end
		end
		return domains
	end

	# Uses the regular expression to attempt to extract the domain from
	# a given email address
	def self.get_address_domain(address)
		match = @domain_regex.match(address)
		if !match.nil?
			return match[1]
		else
			return "UNKNOWN DOMAIN"
		end
	end
end