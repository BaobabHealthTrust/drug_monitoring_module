
require 'rest-client'

$prescription_id = Definition.where(:name => "prescription").first.id
$dispensation_id = Definition.where(:name => "dispensation").first.id
 
def start

  sites = YAML.load_file("#{Rails.root.to_s}/config/sites.yml")
  (sites || []).each do |key, value|
    puts "Getting Data For Site #{key}"
    unless value.blank?
      date = "2014-03-05"
      url = "http://#{value}/drug/art_summary_dispensation?date=#{date}"
      data = JSON.parse(RestClient::Request.execute(:method => :post, :url => url, :timeout => 100000000)) rescue (
        puts "**** Error when pulling data from site #{key}"
       next
      )
      site = Site.where(:name => key).first_or_create
      record(site,date ,data)
    end
  end

end

def record(site, date,data)

  (data['prescriptions'] || []).each do |key,prescription|
    Observation.create({:site_id => site.id,
        :definition_id => $prescription_id,
        :value_numeric => prescription['bottles'],
        :value_drug => key,
        :value_date => date
      })
  end

  (data['dispensations'] || []).each do |key,dispensation|
    Observation.create({:site_id => site.id,
        :definition_id => $dispensation_id,
        :value_numeric => dispensation['bottles'],
        :value_drug => key,
        :value_date => date
      })
  end

  (data['stock_level'].keys || []).each do |drug|

    data['stock_level'][drug].each do |key, value|
      $definition_id = Definition.where(:name => key).first.id
      if value.class.to_s == "Array"
        
        pills = value[0]
        date_of_count = value[1]
        next if date_of_count.blank?
        Observation.create({:site_id => site.id,
            :definition_id => $definition_id,
            :value_numeric => pills,
            :value_drug => drug,          
            :value_date => date_of_count
          })
      else

        Observation.create({:site_id => site.id,
            :definition_id => $definition_id,
            :value_numeric => value,
            :value_drug => drug,
            :value_date => date
          })
      end
    end
  end

end

start
