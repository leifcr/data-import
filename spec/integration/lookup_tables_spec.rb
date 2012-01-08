require 'data-import'

describe "lookup tables" do

  in_memory_mapping do
    import 'Articles' do
      from 'tblArticles', :primary_key => 'sArticleId'
      to 'articles'

      lookup_for :sArticleId
      lookup_for :reference, :column => 'strRef'

      mapping 'strRef' => 'slug'
    end

    import 'Posts' do
      from 'tblPosts', :primary_key => 'sPostId'
      to 'posts'
      dependencies 'Articles'

      mapping 'sPostId' => :id
      mapping 'sArticleId' do |context, value|
        { :article_id => context.definition('Articles').identify_by(:sArticleId, value) }
      end
      mapping 'strArticleRef' do |context, value|
        { :similar_article_id => context.definition('Articles').identify_by(:reference, value) }
      end
    end
  end

  database_setup do
    source.create_table :tblArticles do
      primary_key :sArticleId
      String :strRef
    end

    source.create_table :tblPosts do
      primary_key :sPostId
      Integer :sArticleId
      String :strArticleRef
    end

    target.create_table :articles do
      primary_key :id
      String :slug
    end

    target.create_table :posts do
      primary_key :id
      Integer :article_id
      Integer :similar_article_id
    end

    source[:tblArticles].insert(:sArticleId => 10001,
                                :strRef => 'data-import-is-awesome')
    source[:tblArticles].insert(:sArticleId => 20002,
                                :strRef => 'ruby-is-awesome')
    source[:tblArticles].insert(:sArticleId => 66666)
    source[:tblPosts].insert(:sPostId => 7,
                             :sArticleId => 20002,
                             :strArticleRef => 'data-import-is-awesome')
    source[:tblPosts].insert(:sPostId => 8,
                             :sArticleId => 10001,
                             :strArticleRef => 'ruby-is-awesome')
    source[:tblPosts].insert(:sPostId => 9,
                             :sArticleId => 20002,
                             :strArticleRef => 'data-import-is-awesome')
    source[:tblPosts].insert(:sPostId => 10)

  end

  it 'mapps columns to the new schema' do
    DataImport.run_plan!(plan)
    target_database[:posts].to_a.should == [{:id => 7, :article_id => 2, :similar_article_id => 1},
                                            {:id => 8, :article_id => 1, :similar_article_id => 2},
                                            {:id => 9, :article_id => 2, :similar_article_id => 1},
                                            {:id => 10, :article_id => nil, :similar_article_id => nil}]
  end

end
