import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="udi-calendar"
export default class extends Controller {
  static targets = ["selectedDate", "selectedSlot", "submitBtn", "summary", "summaryText"]
  
  selectSlot(event) {
    const button = event.currentTarget;
    const date = button.dataset.date;
    const slot = button.dataset.slot;
    const session = button.dataset.session;
    const dateObj = new Date(date);
    
    // Remove previous selections
    document.querySelectorAll('.slot-btn').forEach(btn => {
      btn.classList.remove('border-purple-500', 'bg-gradient-to-br', 'from-purple-100', 'to-blue-100', 'ring-2', 'ring-purple-400', 'shadow-lg');
      btn.classList.add('border-gray-200', 'bg-white');
    });
    
    // Highlight selected slot with beautiful styling
    button.classList.remove('border-gray-200', 'bg-white');
    button.classList.add('border-purple-500', 'bg-gradient-to-br', 'from-purple-100', 'to-blue-100', 'ring-2', 'ring-purple-400', 'shadow-lg');
    
    // Update hidden fields
    this.selectedDateTarget.value = date;
    this.selectedSlotTarget.value = slot;
    
    // Update summary with beautiful formatting
    const dayName = dateObj.toLocaleDateString('en-US', { weekday: 'long' });
    const dateStr = dateObj.toLocaleDateString('en-US', { month: 'long', day: 'numeric' });
    const slotLabel = button.querySelector('.font-semibold').textContent;
    
    // Session emoji mapping
    const sessionEmoji = {
      'morning': '🌅',
      'afternoon': '☀️', 
      'evening': '🌙'
    };
    
    this.summaryTextTarget.innerHTML = `
      <div class="flex items-center space-x-2">
        <span>${sessionEmoji[session] || '📅'}</span>
        <span>${dayName}, ${dateStr}</span>
      </div>
      <div class="text-sm text-purple-700 mt-1">${slotLabel} (30 minutes)</div>
    `;
    
    // Show summary with animation
    this.summaryTarget.classList.remove('hidden');
    this.summaryTarget.style.opacity = '0';
    this.summaryTarget.style.transform = 'translateY(-10px)';
    
    setTimeout(() => {
      this.summaryTarget.style.transition = 'all 0.3s ease';
      this.summaryTarget.style.opacity = '1';
      this.summaryTarget.style.transform = 'translateY(0)';
    }, 10);
    
    // Enable submit button with animation
    this.submitBtnTarget.disabled = false;
    this.submitBtnTarget.classList.add('animate-pulse');
    
    setTimeout(() => {
      this.submitBtnTarget.classList.remove('animate-pulse');
    }, 1000);
    
    // Scroll to form on mobile
    if (window.innerWidth < 1024) {
      document.querySelector('form').scrollIntoView({ 
        behavior: 'smooth', 
        block: 'nearest' 
      });
    }
  }
}