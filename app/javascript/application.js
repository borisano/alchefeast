// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Navbar search functionality
document.addEventListener('DOMContentLoaded', function() {
  const navbarSearchForm = document.getElementById('navbar-search-form');

  if (navbarSearchForm) {
    navbarSearchForm.addEventListener('submit', function(e) {
      e.preventDefault();

      const searchInput = document.getElementById('navbar-search-input');
      const queryInput = document.getElementById('navbar-query-input');
      const ingredientsInput = document.getElementById('navbar-ingredients-input');

      const searchValue = searchInput.value.trim();

      // Clear both hidden inputs first
      queryInput.value = '';
      ingredientsInput.value = '';

      if (searchValue) {
        // Check if the search contains commas (indicating ingredient search)
        if (searchValue.includes(',')) {
          // Treat as ingredient search
          ingredientsInput.value = searchValue;
        } else {
          // Treat as recipe name search
          queryInput.value = searchValue;
        }
      }

      // Submit the form
      this.submit();
    });
  }
});

// Search page ingredient suggestions functionality
document.addEventListener('DOMContentLoaded', function() {
  const ingredientsInput = document.getElementById('search_ingredients');

  if (ingredientsInput) {
    // Add some basic styling for better UX
    ingredientsInput.addEventListener('input', function() {
      const value = this.value;
      const ingredients = value.split(',').map(ing => ing.trim()).filter(ing => ing.length > 0);

      // Could add autocomplete or validation here in the future
    });
  }
});
