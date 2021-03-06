require 'acceptance/spec_helper'

describe "lookup tables" do

  in_memory_mapping do
    import 'Articles' do
      from 'tblArticles', :primary_key => 'sArticleId'
      to 'articles'

      lookup_for :sArticleId
      lookup_for :reference, :column => 'strRef', :ignore_case => true

      mapping 'strRef' => 'slug'
    end

    script 'Mark ruby article' do
      dependencies 'Articles'

      body do
        new_id = target_database.db[:articles].insert(:slug => definition('Articles').identify_by(:reference, 'ruby-is-awesome'))

        definition('Mark ruby article').lookup_for(:sArticleId)
        definition('Mark ruby article').row_imported(new_id, {:sArticleId => 0})
      end
    end

    script 'Post about double ruby article' do
      dependencies 'Mark ruby article'

      body do
        target_database.db[:posts].insert(:id => 11, :article_id => definition('Mark ruby article').identify_by(:sArticleId, 0))
      end
    end

    import 'Posts' do
      from 'tblPosts', :primary_key => 'sPostId'
      to 'posts'
      dependencies 'Articles'

      mapping 'sPostId' => :id
      mapping 'sArticleId' do
        { :article_id => definition('Articles').identify_by(:sArticleId, row[:sArticleId]) }
      end
      mapping 'strArticleRef' do
        { :similar_article_id => definition('Articles').identify_by(:reference, row[:strArticleRef]) }
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
                             :strArticleRef => 'ruby-IS-awesome')
    source[:tblPosts].insert(:sPostId => 9,
                             :sArticleId => 20002,
                             :strArticleRef => 'DATA-import-IS-awesome')
    source[:tblPosts].insert(:sPostId => 10)

  end

  it 'maps columns to the new schema' do
    DataImport.run_plan!(plan)
    expect(target_database[:posts].to_a).to eq([{:id => 7, :article_id => 2, :similar_article_id => 1},
                                            {:id => 8, :article_id => 1, :similar_article_id => 2},
                                            {:id => 9, :article_id => 2, :similar_article_id => 1},
                                            {:id => 10, :article_id => nil, :similar_article_id => nil},
                                            {:id => 11, :article_id => 4, :similar_article_id => nil}])
  end

end
