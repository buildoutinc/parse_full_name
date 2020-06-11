# frozen_string_literal: true

RSpec.describe ParseFullName do
  it "has a version number" do
    expect(ParseFullName::VERSION).not_to be nil
  end

  describe "#parse" do
    def verify_name(name, title: "", first_name: "", middle_name: "", last_name: "", nickname: "", suffix: "")
      parsed_name = described_class.parse(name)
      expect(parsed_name.to_h).to eq(
        title: title,
        first_name: first_name,
        middle_name: middle_name,
        last_name: last_name,
        nickname: nickname,
        suffix: suffix
      )
    end

    it "parses first and last names" do
      verify_name("David Davis", first_name: "David", last_name: "Davis")
      verify_name("Davis, David", first_name: "David", last_name: "Davis")
    end

    it "parses middle names" do
      verify_name("David William Davis", first_name: "David", middle_name: "William", last_name: "Davis")
      verify_name("Davis, David William", first_name: "David", middle_name: "William", last_name: "Davis")
    end

    it "parses last names including known prefixes" do
      verify_name("Vincent Van Gogh", first_name: "Vincent", last_name: "Van Gogh")
      verify_name("Van Gogh, Vincent", first_name: "Vincent", last_name: "Van Gogh")
    end

    it "parses compound last names" do
      verify_name("Jüan Martinez de Lorenzo y Gutierez",
                  first_name: "Jüan",
                  middle_name: "Martinez",
                  last_name: "de Lorenzo y Gutierez")
      verify_name("de Lorenzo y Gutierez, Jüan Martinez",
                  first_name: "Jüan",
                  middle_name: "Martinez",
                  last_name: "de Lorenzo y Gutierez")
    end

    it "parses nicknames" do
      verify_name('Saul "Slash" Hudson', first_name: "Saul", last_name: "Hudson", nickname: "Slash")
      verify_name('Hudson, Saul "Slash"', first_name: "Saul", last_name: "Hudson", nickname: "Slash")
      verify_name('Saul (Slash) Hudson', first_name: "Saul", last_name: "Hudson", nickname: "Slash")
      verify_name('Hudson, Saul (Slash)', first_name: "Saul", last_name: "Hudson", nickname: "Slash")
    end

    it "parses known suffixes" do
      verify_name("Sammy Davis, Jr.", first_name: "Sammy", last_name: "Davis", suffix: "Jr.")
      verify_name("Davis, Sammy, Jr.", first_name: "Sammy", last_name: "Davis", suffix: "Jr.")
    end

    it "parses unknown suffixes" do
      verify_name("John Smithe, CLU, CFP, LC", first_name: "John", last_name: "Smithe", suffix: "CLU, CFP, LC")
      verify_name("Smithe, John, CLU, CFP, LC", first_name: "John", last_name: "Smithe", suffix: "CLU, CFP, LC")
    end

    it "parses titles" do
      verify_name("Mr. John E. Smithe", title: "Mr.", first_name: "John", middle_name: "E.", last_name: "Smithe")
      verify_name("Mr. Smithe, John E.", title: "Mr.", first_name: "John", middle_name: "E.", last_name: "Smithe")
    end

    it "autofixes upper and lower case names" do
      verify_name(
        "MR. JOHN E. (JOHNNY) SMITHE, JR.",
        title: "Mr.",
        first_name: "John",
        middle_name: "E.",
        last_name: "Smithe",
        nickname: "Johnny",
        suffix: "Jr."
      )
    end
  end
end
