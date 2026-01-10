// Mobile Menu Toggle
const mobileToggle = document.getElementById('mobileToggle');
const sidebar = document.getElementById('sidebar');

if (mobileToggle) {
    mobileToggle.addEventListener('click', () => {
        sidebar.classList.toggle('open');
    });
}

// Close sidebar when clicking outside on mobile
document.addEventListener('click', (e) => {
    if (window.innerWidth <= 1024) {
        if (!sidebar.contains(e.target) && !mobileToggle.contains(e.target)) {
            sidebar.classList.remove('open');
        }
    }
});

// Smooth Scroll for Navigation Links
document.querySelectorAll('.nav-link').forEach(link => {
    link.addEventListener('click', (e) => {
        e.preventDefault();
        const targetId = link.getAttribute('href');
        
        if (targetId.startsWith('#')) {
            const targetSection = document.querySelector(targetId);
            if (targetSection) {
                // Section'ı görünür yap (reveal animation için)
                targetSection.style.opacity = '1';
                targetSection.style.transform = 'translateY(0)';
                
                const offset = 80; // Offset for fixed header if any
                const targetPosition = targetSection.offsetTop - offset;
                
                window.scrollTo({
                    top: targetPosition,
                    behavior: 'smooth'
                });
                
                // Close mobile menu after navigation
                if (window.innerWidth <= 1024) {
                    sidebar.classList.remove('open');
                }
                
                // Update active state
                updateActiveNav(link);
            }
        }
    });
});

// Update Active Navigation on Scroll
function updateActiveNav(activeLink) {
    document.querySelectorAll('.nav-link').forEach(link => {
        link.classList.remove('active');
    });
    activeLink.classList.add('active');
}

// Intersection Observer for Active Navigation
const sections = document.querySelectorAll('.section[id]');
const navLinks = document.querySelectorAll('.nav-link');

const observerOptions = {
    root: null,
    rootMargin: '-20% 0px -70% 0px',
    threshold: 0
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            const id = entry.target.getAttribute('id');
            navLinks.forEach(link => {
                link.classList.remove('active');
                if (link.getAttribute('href') === `#${id}`) {
                    link.classList.add('active');
                }
            });
        }
    });
}, observerOptions);

sections.forEach(section => {
    observer.observe(section);
});

// Copy to Clipboard Function
function copyCode(button) {
    const codeBlock = button.closest('.code-block');
    const codeElement = codeBlock.querySelector('code');
    
    if (codeElement) {
        const text = codeElement.textContent;
        
        // Create temporary textarea
        const textarea = document.createElement('textarea');
        textarea.value = text;
        textarea.style.position = 'fixed';
        textarea.style.opacity = '0';
        document.body.appendChild(textarea);
        textarea.select();
        
        try {
            document.execCommand('copy');
            
            // Visual feedback
            const originalText = button.textContent;
            button.textContent = '✓ Kopyalandı!';
            button.style.background = '#10b981';
            
            setTimeout(() => {
                button.textContent = originalText;
                button.style.background = '';
            }, 2000);
        } catch (err) {
            console.error('Copy failed:', err);
            button.textContent = 'Kopyalanamadı';
            button.style.background = '#ef4444';
            
            setTimeout(() => {
                button.textContent = 'Kopyala';
                button.style.background = '';
            }, 2000);
        }
        
        document.body.removeChild(textarea);
    }
}

// Enhanced Copy with Modern Clipboard API (if available)
if (navigator.clipboard) {
    // Override copyCode function with modern API
    window.copyCode = async function(button) {
        const codeBlock = button.closest('.code-block');
        const codeElement = codeBlock.querySelector('code');
        
        if (codeElement) {
            const text = codeElement.textContent;
            
            try {
                await navigator.clipboard.writeText(text);
                
                // Visual feedback
                const originalText = button.textContent;
                button.textContent = '✓ Kopyalandı!';
                button.style.background = '#10b981';
                
                setTimeout(() => {
                    button.textContent = originalText;
                    button.style.background = '';
                }, 2000);
            } catch (err) {
                console.error('Copy failed:', err);
                button.textContent = 'Kopyalanamadı';
                button.style.background = '#ef4444';
                
                setTimeout(() => {
                    button.textContent = 'Kopyala';
                    button.style.background = '';
                }, 2000);
            }
        }
    };
}

// Syntax Highlighting Enhancement
function enhanceCodeBlocks() {
    const codeBlocks = document.querySelectorAll('code');
    
    codeBlocks.forEach(block => {
        // Add line numbers for large code blocks
        if (block.textContent.split('\n').length > 10) {
            const pre = block.parentElement;
            if (pre && !pre.classList.contains('line-numbers')) {
                pre.classList.add('line-numbers');
            }
        }
    });
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    enhanceCodeBlocks();
    
    // Set initial active nav based on hash
    if (window.location.hash) {
        const hash = window.location.hash;
        const targetLink = document.querySelector(`.nav-link[href="${hash}"]`);
        const targetSection = document.querySelector(hash);
        
        if (targetLink) {
            updateActiveNav(targetLink);
        }
        
        // Hash ile açılan section'ı görünür yap
        if (targetSection) {
            targetSection.style.opacity = '1';
            targetSection.style.transform = 'translateY(0)';
            
            // Scroll to section
            setTimeout(() => {
                const offset = 80;
                const targetPosition = targetSection.offsetTop - offset;
                window.scrollTo({
                    top: targetPosition,
                    behavior: 'smooth'
                });
            }, 100);
        }
    } else {
        // Set first nav link as active
        const firstLink = document.querySelector('.nav-link');
        if (firstLink) {
            updateActiveNav(firstLink);
        }
    }
    
    // Handle window resize
    let resizeTimer;
    window.addEventListener('resize', () => {
        clearTimeout(resizeTimer);
        resizeTimer = setTimeout(() => {
            if (window.innerWidth > 1024) {
                sidebar.classList.remove('open');
            }
        }, 250);
    });
});

// Keyboard Navigation
document.addEventListener('keydown', (e) => {
    // Close mobile menu with Escape key
    if (e.key === 'Escape' && window.innerWidth <= 1024) {
        sidebar.classList.remove('open');
    }
    
    // Toggle mobile menu with Ctrl/Cmd + M
    if ((e.ctrlKey || e.metaKey) && e.key === 'm') {
        e.preventDefault();
        sidebar.classList.toggle('open');
    }
});

// Add smooth reveal animation for sections
const revealSections = document.querySelectorAll('.section');

const revealObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
});

revealSections.forEach(section => {
    // Eğer hash ile açıldıysa veya ilk section ise görünür yap
    const isHashTarget = window.location.hash && section.id === window.location.hash.substring(1);
    const isFirstSection = section === revealSections[0];
    
    if (!isHashTarget && !isFirstSection) {
        section.style.opacity = '0';
        section.style.transform = 'translateY(20px)';
    }
    section.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
    revealObserver.observe(section);
});

// Search functionality (optional enhancement)
function initSearch() {
    const searchInput = document.createElement('input');
    searchInput.type = 'text';
    searchInput.placeholder = 'Dokümantasyonda ara...';
    searchInput.className = 'search-input';
    searchInput.style.cssText = `
        width: 100%;
        padding: 0.75rem;
        margin: 1rem 0;
        border: 1px solid rgba(255, 255, 255, 0.2);
        border-radius: 0.5rem;
        background: rgba(255, 255, 255, 0.1);
        color: white;
        font-size: 0.9rem;
    `;
    
    const sidebarHeader = document.querySelector('.sidebar-header');
    if (sidebarHeader) {
        sidebarHeader.appendChild(searchInput);
        
        searchInput.addEventListener('input', (e) => {
            const searchTerm = e.target.value.toLowerCase();
            const navLinks = document.querySelectorAll('.nav-link');
            
            navLinks.forEach(link => {
                const text = link.textContent.toLowerCase();
                const listItem = link.parentElement;
                
                if (text.includes(searchTerm) || searchTerm === '') {
                    listItem.style.display = '';
                } else {
                    listItem.style.display = 'none';
                }
            });
        });
    }
}

// Uncomment to enable search
// initSearch();

// Print functionality
window.addEventListener('beforeprint', () => {
    document.querySelectorAll('.copy-btn').forEach(btn => {
        btn.style.display = 'none';
    });
});

window.addEventListener('afterprint', () => {
    document.querySelectorAll('.copy-btn').forEach(btn => {
        btn.style.display = '';
    });
});

// Performance optimization: Lazy load images if any
if ('loading' in HTMLImageElement.prototype) {
    const images = document.querySelectorAll('img[loading="lazy"]');
    images.forEach(img => {
        img.src = img.dataset.src;
    });
}

// Add tooltip for copy buttons
document.querySelectorAll('.copy-btn').forEach(btn => {
    btn.setAttribute('title', 'Kodu panoya kopyala');
});

// Add loading state
window.addEventListener('load', () => {
    document.body.classList.add('loaded');
});

