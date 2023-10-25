RSpec.shared_context 'export results presenter setup' do
  let(:raw_response) { instance_double(Blacklight::Solr::Response, fetch: response) }
  let(:response) { { "docs" => items } }
  let(:items) do
    [{"system_create_dtsi"=>"2023-10-18T21:20:03Z",
    "system_modified_dtsi"=>"2023-10-18T21:20:04Z",
    "has_model_ssim"=>["Acda"],
    "id"=>"ph_006_015_002",
    "accessControl_ssim"=>["b0/58/ad/77/b058ad77-98bc-40f7-b083-9ed756c6aa0a"],
    "contributing_institution_tesim"=>["Robert J. Dole Institute of Politics"],
    "contributing_institution_ssi"=>"Robert J. Dole Institute of Politics",
    "title_tesim"=>["Dole and Goldwater shake hands"],
    "title_ssi"=>"Dole and Goldwater shake hands",
    "date_tesim"=>["1964"],
    "date_ssi"=>"1964",
    "edtf_tesim"=>["1964"],
    "edtf_ssi"=>"1964",
    "creator_tesim"=>["Unknown"],
    "creator_ssi"=>"Unknown",
    "rights_tesim"=>["http://rightsstatements.org/vocab/NKC/1.0/"],
    "rights_ssi"=>"http://rightsstatements.org/vocab/NKC/1.0/",
    "language_tesim"=>["zxx"],
    "language_ssi"=>"zxx",
    "congress_tesim"=>["88th (1963-1964)"],
    "congress_ssi"=>"88th (1963-1964)",
    "collection_title_tesim"=>["Dole Photograph Collection, 1900-2011"],
    "collection_title_ssi"=>"Dole Photograph Collection, 1900-2011",
    "physical_location_tesim"=>["Collection 012, Box 6, Folder 15"],
    "physical_location_ssi"=>"Collection 012, Box 6, Folder 15",
    "collection_finding_aid_tesim"=>
      ["https://dolearchivecollections.ku.edu/index.php?p=collections/controlcard&id=47&q="],
    "collection_finding_aid_ssi"=>
      "https://dolearchivecollections.ku.edu/index.php?p=collections/controlcard&id=47&q=",
    "identifier_tesim"=>["ph_006_015_002"],
    "identifier_ssi"=>"ph_006_015_002",
    "preview_tesim"=>
      ["https://dolearchives.omeka.net/exhibits/show/voices-from-the-big-first/item/323"],
    "preview_ssi"=>
      "https://dolearchives.omeka.net/exhibits/show/voices-from-the-big-first/item/323",
    "available_at_tesim"=>
      ["https://dolearchives.omeka.net/exhibits/show/voices-from-the-big-first/item/323"],
    "available_at_ssi"=>
      "https://dolearchives.omeka.net/exhibits/show/voices-from-the-big-first/item/323",
    "record_type_tesim"=>["black-and-white photograph"],
    "record_type_ssi"=>"black-and-white photograph",
    "policy_area_tesim"=>["Government Operations and Politics"],
    "policy_area_ssi"=>"Government Operations and Politics",
    "names_tesim"=>
      ["Goldwater, Barry M. (Barry Morris), 1909-1998",
       "Dole, Robert J., 1923-2021"],
    "names_ssi"=>"Dole, Robert J., 1923-2021",
    "description_tesim"=>
      ["Congressman Bob Dole and Senator Barry Goldwater shaking hands with an American flag in the background."],
    "description_ssi"=>
      "Congressman Bob Dole and Senator Barry Goldwater shaking hands with an American flag in the background.",
    "dc_type_tesim"=>["StillImage"],
    "dc_type_ssi"=>"StillImage",
    "bulkrax_identifier_tesim"=>["b-1-3"],
    "read_access_group_ssim"=>["public"],
    "_version_"=>1780129730755821568,
    "timestamp"=>"2023-10-18T21:20:04.092Z",
    "score"=>1.0},
    {"system_create_dtsi"=>"2023-10-18T21:20:08Z",
    "system_modified_dtsi"=>"2023-10-18T21:20:08Z",
    "has_model_ssim"=>["Acda"],
    "id"=>"LSqyFpjhe3g",
    "accessControl_ssim"=>["11/5c/54/34/115c5434-a01e-43c8-9504-5fe7b64e3594"],
    "contributing_institution_tesim"=>["Robert J. Dole Institute of Politics"],
    "contributing_institution_ssi"=>"Robert J. Dole Institute of Politics",
    "title_tesim"=>["Kassebaum-Baker, Sen. Nancy, 4/16/2009"],
    "title_ssi"=>"Kassebaum-Baker, Sen. Nancy, 4/16/2009",
    "date_tesim"=>["2009 April 16"],
    "date_ssi"=>"2009 April 16",
    "edtf_tesim"=>["2009-04-16"],
    "edtf_ssi"=>"2009-04-16",
    "creator_tesim"=>["Williams, Brien R."],
    "creator_ssi"=>"Williams, Brien R.",
    "rights_tesim"=>["http://rightsstatements.org/vocab/CNE/1.0/"],
    "rights_ssi"=>"http://rightsstatements.org/vocab/CNE/1.0/",
    "language_tesim"=>["eng"],
    "language_ssi"=>"eng",
    "congress_tesim"=>["111th (2009-2010)"],
    "congress_ssi"=>"111th (2009-2010)",
    "collection_title_tesim"=>["Dole Institute Oral History Project, 2002-2009"],
    "collection_title_ssi"=>"Dole Institute Oral History Project, 2002-2009",
    "physical_location_tesim"=>
      ["Collection 018, Nancy Kassebaum-Baker Oral History from 2009-04-16"],
    "physical_location_ssi"=>
     "Collection 018, Nancy Kassebaum-Baker Oral History from 2009-04-16",
    "collection_finding_aid_tesim"=>
      ["https://dolearchivecollections.ku.edu/index.php?p=collections/findingaid&id=51&q="],
    "collection_finding_aid_ssi"=>
      "https://dolearchivecollections.ku.edu/index.php?p=collections/findingaid&id=51&q=",
    "identifier_tesim"=>["LSqyFpjhe3g"],
    "identifier_ssi"=>"LSqyFpjhe3g",
    "preview_tesim"=>["https://www.youtube.com/watch?v=LSqyFpjhe3g"],
    "preview_ssi"=>"https://www.youtube.com/watch?v=LSqyFpjhe3g",
    "available_at_tesim"=>["https://dolearchives.omeka.net/items/show/234"],
    "available_at_ssi"=>"https://dolearchives.omeka.net/items/show/234",
    "record_type_tesim"=>["moving image"],
    "record_type_ssi"=>"moving image",
    "policy_area_tesim"=>["Agriculture and Food, Health, International Affairs"],
    "policy_area_ssi"=>"Agriculture and Food, Health, International Affairs",
    "names_tesim"=>
      ["Dole, Robert J., 1923-2021", "Baker, Nancy Kassebaum, 1932-"],
    "names_ssi"=>"Baker, Nancy Kassebaum, 1932-",
    "description_tesim"=>
      ["In this 2009 oral history interview with Brien R. Williams, Kassebaum-Baker talks about Senator Dole's work ethic and the issues of abortion, the Panama Canal, and wheat subsidies on the campaign trail.  Baker represented Kansas in the U.S. Senate (1978-1997). She was the first female senator not elected to a seat held by her husband nor appointed to fill out a deceased husband’s term."],
    "description_ssi"=>
      "In this 2009 oral history interview with Brien R. Williams, Kassebaum-Baker talks about Senator Dole's work ethic and the issues of abortion, the Panama Canal, and wheat subsidies on the campaign trail.  Baker represented Kansas in the U.S. Senate (1978-1997). She was the first female senator not elected to a seat held by her husband nor appointed to fill out a deceased husband’s term.",
    "dc_type_tesim"=>["MovingImage"],
    "dc_type_ssi"=>"MovingImage",
    "bulkrax_identifier_tesim"=>["b-1-7"],
    "read_access_group_ssim"=>["public"],
    "_version_"=>1780129735782694912,
    "timestamp"=>"2023-10-18T21:20:08.887Z",
    "score"=>1.0
    }]
  end
end
