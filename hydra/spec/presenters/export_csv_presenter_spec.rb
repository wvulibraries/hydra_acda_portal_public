require 'rails_helper'

RSpec.describe ExportCsvPresenter do
  include_context 'export results presenter setup'

  describe '#to_csv' do
    subject { described_class.new(raw_response).to_csv }

    it { is_expected.to be_a(String) }
    it { is_expected.to eq("contributing_institution,title,date,edtf,creator,rights,language,congress,collection_title,physical_location,collection_finding_aid,identifier,preview,available_at,record_type,policy_area,names,description,dc_type,bulkrax_identifier\nRobert J. Dole Institute of Politics,Dole and Goldwater shake hands,1964,1964,Unknown,http://rightsstatements.org/vocab/NKC/1.0/,zxx,88th (1963-1964),\"Dole Photograph Collection, 1900-2011\",\"Collection 012, Box 6, Folder 15\",https://dolearchivecollections.ku.edu/index.php?p=collections/controlcard&id=47&q=,http://congressarchivesdev.lib.wvu.edu/record/ph_006_015_002,https://dolearchives.omeka.net/exhibits/show/voices-from-the-big-first/item/323,https://dolearchives.omeka.net/exhibits/show/voices-from-the-big-first/item/323,black-and-white photograph,Government Operations and Politics,\"Goldwater, Barry M. (Barry Morris), 1909-1998; Dole, Robert J., 1923-2021\",Congressman Bob Dole and Senator Barry Goldwater shaking hands with an American flag in the background.,StillImage,b-1-3\nRobert J. Dole Institute of Politics,\"Kassebaum-Baker, Sen. Nancy, 4/16/2009\",2009-04-16,2009-04-16,\"Williams, Brien R.\",http://rightsstatements.org/vocab/CNE/1.0/,eng,111th (2009-2010),\"Dole Institute Oral History Project, 2002-2009\",\"Collection 018, Nancy Kassebaum-Baker Oral History from 2009-04-16\",https://dolearchivecollections.ku.edu/index.php?p=collections/findingaid&id=51&q=,http://congressarchivesdev.lib.wvu.edu/record/LSqyFpjhe3g,https://www.youtube.com/watch?v=LSqyFpjhe3g,https://dolearchives.omeka.net/items/show/234,moving image,\"Agriculture and Food, Health, International Affairs\",\"Dole, Robert J., 1923-2021; Baker, Nancy Kassebaum, 1932-\",\"In this 2009 oral history interview with Brien R. Williams, Kassebaum-Baker talks about Senator Dole's work ethic and the issues of abortion, the Panama Canal, and wheat subsidies on the campaign trail.  Baker represented Kansas in the U.S. Senate (1978-1997). She was the first female senator not elected to a seat held by her husband nor appointed to fill out a deceased husband’s term.\",MovingImage,b-1-7\n") }
  end
end
