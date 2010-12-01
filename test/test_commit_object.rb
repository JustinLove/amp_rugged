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

class Rugged::Commit
  def inspect
    "commit #{sha}"
  end
end

class TestRuggedCommitObject < AmpTestCase
  
  def setup
    super

    `git init --bare #{tempdir}`
    repo = Rugged::Repository.new(tempdir)
    @tree = repo.write('', 'tree')
    repo.lookup(@tree)
    @content_parent = "tree #{@tree}\n"+
               "author Michael "+
               "Edgar <michael.j.edgar@dartmouth.edu> 1273865360 -0400\ncommitter "+
               "Michael Edgar <michael.j.edgar@dartmouth.edu> 1273865360 -0400\n\n"+
               "Removed the gemspec from the repo\n"
    @parent = repo.write(@content_parent, 'commit')
    repo.lookup(@parent)
    @content = "tree #{@tree}\n"+
               "parent #{@parent}\nauthor Michael "+
               "Edgar <michael.j.edgar@dartmouth.edu> 1273865360 -0400\ncommitter "+
               "Michael Edgar <michael.j.edgar@dartmouth.edu> 1273865360 -0400\n\n"+
               "Removed the gemspec from the repo\n"
    sha = repo.write(@content, 'commit')
    @commit_obj = repo.lookup(sha)
  end
  
  def test_correct_type
    assert_equal 'commit', @commit_obj.type
  end
  
  def test_correct_content
    assert_equal @content, @commit_obj.read_raw.first
  end
  
  def test_tree_ref
    assert_equal @tree, @commit_obj.tree.sha
  end
  
  def test_parent_refs
    assert_equal @parent, @commit_obj.parents.first.sha
  end
  
  def test_author
    assert_equal "Michael Edgar", @commit_obj.author.name
  end
  
  def test_committer
    assert_equal "Michael Edgar", @commit_obj.author.name
  end
  
  def test_date
    assert_equal Time.at(1273865360), @commit_obj.author.time
  end
  
  def test_messages
    assert_equal "Removed the gemspec from the repo\n", @commit_obj.message
  end
end
