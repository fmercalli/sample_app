require 'spec_helper'

describe "Authentication" do
  subject {page}
  
  describe 'signin page' do
    before {visit signin_path}
    it {should have_selector('h1', text: 'Sign in')}
    it {should have_selector('title', text: 'Sign in')}
  end
  
  describe 'signin' do
    
    describe 'with invalid information' do
      before {invalid_sign_in}
      
      it {should have_selector('title', text: 'Sign in')}
      it {should have_error_message('Invalid')}

      it {should_not have_link('Users')}
      it {should_not have_link('Profile')}
      it {should_not have_link('Settings')}
      
      describe 'after visiting another page' do
        before {click_link "Home"}
        it {should_not have_error_message('Invalid')}
      end
    end
    
    describe 'with valid information' do
      let(:user) {FactoryGirl.create(:user)}
      before {sign_in user}
      
      it {should have_selector('title', text: user.name)}
      it {should have_link('Users', href: users_path)}
      it {should have_link('Profile', href: user_path(user))}
      it {should have_link('Settings', href: edit_user_path(user))}
      it {should have_link('Sign out', href: signout_path)}
      it {should_not have_link('Sign in', href: signin_path)}
      
      describe 'followed by signout' do
        before {click_link 'Sign out'}
        it {should have_link('Sign in')}
      end

      describe 'followed by new' do
        before {visit new_user_path}
        
        # come mai il testo non dice che l'istruzione sotto non funziona più a seguito delle modifiche di Listing 10.31?
        # it {should have_content('Welcome to the Sample App')} 
        it {should have_content('view my profile')}
      end

      describe 'followed by submitting a POST request to the User#create action' do
        before {post users_path}
        
        specify {response.should redirect_to(root_path)}
      end

    end    
  end
  
  describe 'authorization' do
    describe 'for non-signed-in users' do
      let(:user) {FactoryGirl.create(:user)}
      
      describe 'in the Users controller' do
        
        describe 'visiting the edit page' do
          before {visit edit_user_path(user)}
          
          it {should have_selector('title', text: 'Sign in')}
        end
        
        describe 'submitting to the update action' do
          before {put user_path(user)}
          
          specify {response.should redirect_to(signin_path)}
        end
        
        describe 'visiting the user index' do
          before {visit users_path}
          
          it {should have_selector('title', text: 'Sign in')}
        end
      end

      describe 'as wrong user' do
        let(:wrong_user) {FactoryGirl.create(:user, email: 'wrong@example.com')}
        before {sign_in user}
        
        describe 'visiting User#edit page' do
          before {visit edit_user_path(wrong_user)}
          
          it {should_not have_selector('title', text: full_title('Edit user'))}
        end
        
        describe 'submitting a PUT request to the User#update action' do
          before {put user_path(wrong_user)}
          
          specify {response.should redirect_to(root_path)}
        end
      end

      describe 'when attempting to visit a protected page' do
        before do
          visit edit_user_path(user)
          valid_sign_in user
        end
        
        describe 'after signing in' do
          it 'should render the desired protected page' do
            page.should have_selector('title', text: 'Edit user')
          end
        end
      end
      
      describe 'in the Microposts controller' do
        describe 'submitting to the create action' do
          before {post microposts_path}
          specify {response.should redirect_to(signin_path)}
        end

        describe 'submitting to the destroy action' do
          before do
            micropost = FactoryGirl.create(:micropost)
            delete micropost_path(micropost)
          end
          specify {response.should redirect_to(signin_path)}
        end
      end
       
    end

    describe 'as non-admin user' do
      let(:user) {FactoryGirl.create(:user)}
      let(:non_admin) {FactoryGirl.create(:user)}
      before {sign_in non_admin}
      
      describe 'submit a DELETE request to the Users#destroy action' do
        before {delete user_path(user)}
        specify {response.should redirect_to(root_path)}
      end
    end

    describe 'as admin user' do
      let(:user) {FactoryGirl.create(:admin)}
      before {sign_in user}
      
      describe 'submit a DELETE request on myself to the Users#destroy action' do
        before {delete user_path(user)}
        specify {response.should redirect_to(root_path)}
      end
    end

    describe 'accessible attributes' do
      it 'should not allow access to admin' do
        expect do
          User.new(admin: true)
        end.should raise_error(ActiveModel::MassAssignmentSecurity::Error)
      end
    end
  end
end
