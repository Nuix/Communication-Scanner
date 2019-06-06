# Menu Title: Communication Scanner
# Needs Case: true

script_directory = File.dirname(__FILE__)

# Bootstrap Nx library for settings dialog and progress dialog
require_relative "Nx.jar"
java_import "com.nuix.nx.NuixConnection"
java_import "com.nuix.nx.LookAndFeelHelper"
java_import "com.nuix.nx.dialogs.ChoiceDialog"
java_import "com.nuix.nx.dialogs.TabbedCustomDialog"
java_import "com.nuix.nx.dialogs.CommonDialogs"
java_import "com.nuix.nx.dialogs.ProgressDialog"

LookAndFeelHelper.setWindowsIfMetal
NuixConnection.setUtilities($utilities)
NuixConnection.setCurrentNuixVersion(NUIX_VERSION)

# Load address helper class
load File.join(script_directory,"AddressHelper.rb")

addresses = nil
domains = nil

use_selected_items = false
if !$current_selected_items.nil? && $current_selected_items.size > 0
	use_selected_items = true
else
	use_selected_items = false
end

# Build a listing of addresses present in the case.  This process can take some time
# so we show a progress dialog while were doing it.
ProgressDialog.forBlock do |pd|
	pd.setTitle("Communication Scanner")
	pd.setAbortButtonVisible(false)
	pd.setSubProgressVisible(false)
	pd.setLogVisible(false)

	items = nil

	if use_selected_items
		pd.logMessage("Using selected items...")
		items = $current_selected_items
	else
		pd.setMainStatusAndLogIt("Locating items with communications...")
		items = $current_case.searchUnsorted("has-communication:1")
	end
	
	pd.setMainStatusAndLogIt("Locating all distinct addresses...")
	pd.setMainProgress(0,items.size)
	addresses = AddressHelper.get_distinct_addresses(items) do |index|
		pd.setMainProgress(index+1)
	end
	pd.setMainStatusAndLogIt("Located #{addresses.size} distinct addresses")

	pd.setMainStatusAndLogIt("Determining all distinct domains...")
	pd.setMainProgress(0,addresses.size)
	domains = AddressHelper.get_distinct_domains(addresses.keys) do |index|
		pd.setMainProgress(index+1)
	end
	pd.setMainStatusAndLogIt("Located #{domains.size} distinct domains")
	pd.dispose
end

# Build the settings dialog
dialog = TabbedCustomDialog.new("Communication Scanner")
dialog.setHelpUrl("https://github.com/Nuix/Communication-Scanner")

main_tab = dialog.addTab("main_tab","Main")
if use_selected_items
	main_tab.appendHeader("Using #{$current_selected_items.size} selected items")
else
	main_tab.appendHeader("Scope Query")
	main_tab.appendTextArea("scope_query","","has-communication:1")
end

addresses_tab = dialog.addTab("addresses_tab","Addresses")
# Require Addresses section
addresses_tab.appendCheckBox("require_addresses","Require Addresses",false)
addresses_tab.appendRadioButton("has_only_selected_addresses","All selected must be present, no others may be present","addresses_filter",true)
addresses_tab.appendRadioButton("has_at_least_selected_addresses","All selected must be present, others may also be present","addresses_filter",false)
addresses_tab.appendRadioButton("ignore_unselected_addresses","Ignore items with any address other than these","addresses_filter",false)
addresses_tab.appendRadioButton("require_other_addresses","Require addresses other than these","addresses_filter",false)
addresses_tab.appendStringChoiceTable("target_addresses","Required Addresses",addresses.keys.sort)
addresses_tab.enabledOnlyWhenChecked("target_addresses","require_addresses")
addresses_tab.enabledOnlyWhenChecked("has_only_selected_addresses","require_addresses")
addresses_tab.enabledOnlyWhenChecked("has_at_least_selected_addresses","require_addresses")
addresses_tab.enabledOnlyWhenChecked("ignore_unselected_addresses","require_addresses")
addresses_tab.enabledOnlyWhenChecked("require_other_addresses","require_addresses")

domains_tab = dialog.addTab("domains_tab","Domains")
# Require Domains section
domains_tab.appendCheckBox("require_domains","Require Domains",false)
domains_tab.appendRadioButton("has_only_selected_domains","All selected must be present, no others may be present","domains_filter",true)
domains_tab.appendRadioButton("has_at_least_selected_domains","All selected must be present, others may also be present","domains_filter",false)
domains_tab.appendRadioButton("ignore_unselected_domains","Ignore items with any domain other than these","domains_filter",false)
domains_tab.appendRadioButton("require_other_domains","Require domains other than these","domains_filter",false)
domains_tab.appendStringChoiceTable("target_domains","Required Domains",domains.keys.sort)
domains_tab.enabledOnlyWhenChecked("target_domains","require_domains")
domains_tab.enabledOnlyWhenChecked("has_only_selected_domains","require_domains")
domains_tab.enabledOnlyWhenChecked("has_at_least_selected_domains","require_domains")
domains_tab.enabledOnlyWhenChecked("ignore_unselected_domains","require_domains")
domains_tab.enabledOnlyWhenChecked("require_other_domains","require_domains")

subject_tab = dialog.addTab("subject_tab","Subject")
subject_tab.appendCheckBox("match_subject","Match Subject",false)
subject_tab.appendTextField("subject_pattern","Regex Pattern","")
subject_tab.appendCheckBox("subject_match_case_insensitive","Case insensitive",true)
subject_tab.enabledOnlyWhenChecked("subject_pattern","match_subject")
subject_tab.enabledOnlyWhenChecked("subject_match_case_insensitive","match_subject")

reporting_tab = dialog.addTab("reporting_tab","Reporting")
reporting_tab.appendTextField("tag_template","Tag","CommunicationScanMatch")
reporting_tab.appendCheckBox("include_families","Tag Family Members",false)
reporting_tab.appendCheckBox("apply_address_list","Record Address List as Custom Metadata",false)
reporting_tab.appendTextField("address_list_field_name","Address List Field Name","Address List")

# Menu item allowing user to check addresses based on their presence in a selected text file
dialog.addMenu("Selection","Import Address Selection...") do
	import_file = CommonDialogs.openFileDialog("C:\\","Address List Text File (*.txt)","txt","Import Address Selection")
	if import_file.nil? == false
		import_values = {}
		File.readlines(import_file.getPath).each do |value|
			import_values[value.downcase.strip] = true
		end
		matched_values = {}
		table = addresses_tab.getControl("target_addresses")
		table_model = table.getTableModel
		table_model.getChoices.each do |choice|
			normalized_choice_value = choice.getValue.downcase.strip
			if import_values[normalized_choice_value] == true
				choice.setSelected(true)
				matched_values[normalized_choice_value] = true
			end
		end
		addresses_tab.setChecked("require_addresses",true)

		# Report which addresses in the import list did not have a corresponding
		# value to check in the list
		unmatched_values = []
		import_values.keys.each do |value|
			if matched_values[value] != true
				unmatched_values << value
			end
		end

		if unmatched_values.size > 0
			message = "Import file contained #{import_values.size} addresses, of which #{unmatched_values.size} addresses " +
				"were not found to be present in the list built from the case:\n\n"
			message += unmatched_values.take(10).join("\n")
			if unmatched_values.size > 10
				message += "... #{unmatched_values.size - 10} more ...\n\n"
				message += "See script console or logs for full list"
			end
			CommonDialogs.showWarning(message,"Some Imported Addresses Not Checked")
			# Make sure full list gets to Nuix log
			log_message = "Import file contained #{import_values.size} addresses, of which #{unmatched_values.size} addresses " +
				"were not found to be present in the list built from the case:\n\n#{unmatched_values.join("\n")}"
			puts log_message
		end
		table_model.refreshTable
	end
end

# Menu item allowing user to check domains based on their presence in a selected text file
dialog.addMenu("Selection","Import Domain Selection...") do
	import_file = CommonDialogs.openFileDialog("C:\\","Domain List Text File (*.txt)","txt","Import Domain Selection")
	if import_file.nil? == false
		import_values = {}
		File.readlines(import_file.getPath).each do |value|
			import_values[value.downcase.strip] = true
		end
		matched_values = {}
		table = domains_tab.getControl("target_domains")
		table_model = table.getTableModel
		table_model.getChoices.each do |choice|
			normalized_choice_value = choice.getValue.downcase.strip
			if import_values[normalized_choice_value] == true
				choice.setSelected(true)
				matched_values[normalized_choice_value] = true
			end
		end
		domains_tab.setChecked("require_domains",true)

		# Report which domains in the import list did not have a corresponding
		# value to check in the list
		unmatched_values = []
		import_values.keys.each do |value|
			if matched_values[value] != true
				unmatched_values << value
			end
		end
		if unmatched_values.size > 0
			message = "Import file contained #{import_values.size} domains, of which #{unmatched_values.size} domains " +
				"were not found to be present in the list built from the case:\n\n"
			message += unmatched_values.take(10).join("\n")
			if unmatched_values.size > 10
				message += "... #{unmatched_values.size - 10} more ...\n\n"
				message += "See script console or logs for full list"
			end
			CommonDialogs.showWarning(message,"Some Imported Domains Not Checked")
			# Make sure full list gets to Nuix log
			log_message = "Import file contained #{import_values.size} domains, of which #{unmatched_values.size} domains " +
				"were not found to be present in the list built from the case:\n\n#{unmatched_values.join("\n")}"
			puts log_message
		end
		table_model.refreshTable
	end
end

dialog.display
if dialog.getDialogResult == true
	ProgressDialog.forBlock do |pd|
		values = dialog.toMap
		pd.setTitle("Communication Scanner")
		pd.setMainStatus("")

		# Determine if we are using selected items or a scope query and
		# then obtain appropriate items
		items = nil
		if use_selected_items
			items = $current_selected_items
		else
			items = $current_case.searchUnsorted(values["scope_query"])
		end
		pd.logMessage("Items to Scan: #{items.size}")

		# Build hashes for faster lookup of addresses and domains
		target_addresses = {}
		values["target_addresses"].each do |address|
			target_addresses[address] = true
		end

		target_domains = {}
		values["target_domains"].each do |domain|
			target_domains[domain] = true
		end

		passed_items = []

		# Build regular expression for subject matching
		subject_regex = nil
		if values["subject_match_case_insensitive"]
			subject_regex = /#{values["subject_pattern"]}/i
		else
			subject_regex = /#{values["subject_pattern"]}/
		end

		if values["match_subject"]
			pd.logMessage("Subject Regex: #{values["subject_pattern"]}")
		end

		# Scan items for communications which match our criteria
		pd.setMainProgress(0,items.size)
		pd.setMainStatusAndLogIt("Scanning items for qualification...")
		items.each_with_index do |item,item_index|
			break if pd.abortWasRequested
			item_addresses = nil
			item_domains = nil
			test_failed = false
			pd.setMainProgress(item_index+1)

			if values["match_subject"] && !test_failed
				subject = item.getProperties["Subject"]
				if subject.nil? || subject !~ subject_regex
					test_failed = true
				end
			end

			# Address criteria
			if values["require_addresses"] && !test_failed
				item_addresses = AddressHelper.get_distinct_addresses(item)
				if item_addresses.size < 1
					test_failed = true
				else
					if values["require_other_addresses"]
						# Check that an address outside selection exists
						external_address = false
						item_addresses.keys.each do |item_address|
							if target_addresses[item_address] != true
								external_address = true
								break
							end
						end
						test_failed = true if external_address == false
					end

					if !test_failed && (values["has_only_selected_addresses"] || values["has_at_least_selected_addresses"])
						# Check that each selected address is present on the communication
						target_addresses.keys.each do |required_address|
							if item_addresses[required_address] != true
								test_failed = true
								break
							end 
						end
					end
					
					if !test_failed && (values["has_only_selected_addresses"] || values["ignore_unselected_addresses"])
						# Check that each communication address is present in the selection
						item_addresses.keys.each do |item_address|
							if target_addresses[item_address] != true
								test_failed = true
								break
							end
						end
					end
				end
			end

			# Domain criteria
			if values["require_domains"] && !test_failed
				item_addresses ||= AddressHelper.get_distinct_addresses(item)
				item_domains = AddressHelper.get_distinct_domains(item_addresses.keys)
				if item_domains.size < 1
					test_failed = true
				else
					if values["require_other_domains"]
						# Check that an domain outside selection exists
						external_domain = false
						item_domains.keys.each do |item_domain|
							if target_domains[item_domain] != true
								external_domain = true
								break
							end
						end
						test_failed = true if external_domain == false
					end

					if !test_failed && (values["has_only_selected_domains"] || values["has_at_least_selected_domains"])
						# Check that each selected domain is present on the communication
						target_domains.keys.each do |required_address|
							if item_domains[required_address] != true
								test_failed = true
								break
							end 
						end
					end
					
					if !test_failed && (values["has_only_selected_domains"] || values["ignore_unselected_domains"])
						# Check that each communication domain is present in the selection
						item_domains.keys.each do |item_domain|
							if target_domains[item_domain] != true
								test_failed = true
								break
							end
						end
					end
				end
			end

			if !test_failed
				# Annotate address list as custom metadata if settings called for it
				if values["apply_address_list"]
					item_addresses ||= AddressHelper.get_distinct_addresses(item)
					item_custom_metadata = item.getCustomMetadata
					item_custom_metadata[values["address_list_field_name"]] = item_addresses.keys.sort.join("\n")
				end
				
				passed_items << item
			end
		end

		iutil = $utilities.getItemUtility
		annotater = $utilities.getBulkAnnotater

		pd.logMessage("Qualified Items: #{passed_items.size}")

		# Resolve to families if settings specified to do so
		if values["include_families"]
			pd.setMainStatusAndLogIt("Including families...")
			passed_items = iutil.findFamilies(passed_items)
			pd.logMessage("Qualified Items with Families: #{passed_items.size}")
		end

		# Tag items
		if !pd.abortWasRequested
			pd.setMainStatusAndLogIt("Tagging items...")
			tag = values["tag_template"]
			pd.logMessage("Tag: #{tag}")
			annotater.addTag(tag,passed_items)
		end

		# Finish things off
		if !pd.abortWasRequested
			pd.setMainStatusAndLogIt("Completed")
		else
			pd.setMainStatusAndLogIt("User Aborted")
		end
	end
end