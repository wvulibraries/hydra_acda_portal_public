require 'rails_helper'

RSpec.describe ExportXmlPresenter do
  include_context 'export results presenter setup'

  describe '#to_xml' do
    subject { described_class.new(raw_response).to_xml }
    let(:expected_xml) do
      <<~XML.strip_heredoc
        <?xml version="1.0" encoding="UTF-8"?>
        <records>
          <record>
            <contributing_institution>Robert J. Dole Institute of Politics</contributing_institution>
            <title>Dole and Goldwater shake hands</title>
            <date>1964</date>
            <edtf>1964</edtf>
            <creator>Unknown</creator>
            <rights>http://rightsstatements.org/vocab/NKC/1.0/</rights>
            <language>zxx</language>
            <congress>88th (1963-1964)</congress>
            <collection_title>Dole Photograph Collection, 1900-2011</collection_title>
            <physical_location>Collection 012, Box 6, Folder 15</physical_location>
            <collection_finding_aid>https://dolearchivecollections.ku.edu/index.php?p=collections/controlcard&amp;id=47&amp;q=</collection_finding_aid>
            <identifier>http://congressarchivesdev.lib.wvu.edu/record/ph_006_015_002</identifier>
            <preview>https://dolearchives.omeka.net/exhibits/show/voices-from-the-big-first/item/323</preview>
            <available_at>https://dolearchives.omeka.net/exhibits/show/voices-from-the-big-first/item/323</available_at>
            <record_type>black-and-white photograph</record_type>
            <policy_area>Government Operations and Politics</policy_area>
            <names>Goldwater, Barry M. (Barry Morris), 1909-1998; Dole, Robert J., 1923-2021</names>
            <description>Congressman Bob Dole and Senator Barry Goldwater shaking hands with an American flag in the background.</description>
            <dc_type>StillImage</dc_type>
            <bulkrax_identifier>b-1-3</bulkrax_identifier>
          </record>
          <record>
            <contributing_institution>Robert J. Dole Institute of Politics</contributing_institution>
            <title>Kassebaum-Baker, Sen. Nancy, 4/16/2009</title>
            <date>2009-04-16</date>
            <edtf>2009-04-16</edtf>
            <creator>Williams, Brien R.</creator>
            <rights>http://rightsstatements.org/vocab/CNE/1.0/</rights>
            <language>eng</language>
            <congress>111th (2009-2010)</congress>
            <collection_title>Dole Institute Oral History Project, 2002-2009</collection_title>
            <physical_location>Collection 018, Nancy Kassebaum-Baker Oral History from 2009-04-16</physical_location>
            <collection_finding_aid>https://dolearchivecollections.ku.edu/index.php?p=collections/findingaid&amp;id=51&amp;q=</collection_finding_aid>
            <identifier>http://congressarchivesdev.lib.wvu.edu/record/LSqyFpjhe3g</identifier>
            <preview>https://www.youtube.com/watch?v=LSqyFpjhe3g</preview>
            <available_at>https://dolearchives.omeka.net/items/show/234</available_at>
            <record_type>moving image</record_type>
            <policy_area>Agriculture and Food, Health, International Affairs</policy_area>
            <names>Dole, Robert J., 1923-2021; Baker, Nancy Kassebaum, 1932-</names>
            <description>In this 2009 oral history interview with Brien R. Williams, Kassebaum-Baker talks about Senator Dole's work ethic and the issues of abortion, the Panama Canal, and wheat subsidies on the campaign trail.  Baker represented Kansas in the U.S. Senate (1978-1997). She was the first female senator not elected to a seat held by her husband nor appointed to fill out a deceased husband’s term.</description>
            <dc_type>MovingImage</dc_type>
            <bulkrax_identifier>b-1-7</bulkrax_identifier>
          </record>
        </records>
      XML
    end

    it { is_expected.to be_a(String) }
    it { is_expected.to eq(expected_xml) }
  end
end
