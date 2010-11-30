##################################################################
#                  Licensing Information                         #
#                                                                #
#  The following code is licensed, as standalone code, under     #
#  the Ruby License, unless otherwise directed within the code.  #
#                                                                #
#  For information on the license of this code when distributed  #
#  with and used in conjunction with the other modules in the    #
#  Amp project, please see the root-level LICENSE file.          #
#                                                                #
#  © Michael J. Edgar and Ari Brown, 2009-2010                   #
#                                                                #
##################################################################

require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper'))

class TestRuggedTagObject < AmpTestCase
  
  def setup
    super

    @message = "GIT 1.5.0\n-----BEGIN PGP SIGNATURE-----\nVersion: GnuPG v1.4.6 (GNU/Linux)\n\n"+
               "iD8DBQBF0lGqwMbZpPMRm5oRAuRiAJ9ohBLd7s2kqjkKlq1qqC57SbnmzQCdG4ui\nnLE/L9aUXdWeT"+
               "FPron96DLA=\n=2E+0\n-----END PGP SIGNATURE-----"

    `git init --bare #{tempdir}`
    repo = Rugged::Repository.new(tempdir)
    @tagger = Rugged::Person.new('Junio C Hamano', 'junkio@cox.net', 1171411200)
    @commit = Rugged::Blob.new(repo)
    @commit.content = ''
    @target_sha = @commit.write
    @tag_obj = Rugged::Tag.new(repo)
    @tag_obj.target = @commit
    @tag_obj.name = 'v1.5.0'
    @tag_obj.tagger = @tagger
    @tag_obj.message = @message
  end
  
  def test_correct_type
    assert_equal 'tag', @tag_obj.type
  end
  
  def test_target_type
    assert_equal "blob", @tag_obj.target_type
  end

  def test_target
    assert_equal @commit, @tag_obj.target
  end
  
  def test_object
    assert_equal @target_sha, @tag_obj.target.sha
  end
  
  def test_tagger
    assert_equal @tagger.name, @tag_obj.tagger.name
  end
  
  def test_date
    assert_equal Time.at(1171411200), @tag_obj.tagger.time
  end
  
  def test_tag
    assert_equal "v1.5.0", @tag_obj.name
  end
  
  def test_message
    assert_equal @message, @tag_obj.message
  end
end
