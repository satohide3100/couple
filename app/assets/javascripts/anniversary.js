// Anniversary Page JavaScript

document.addEventListener('DOMContentLoaded', function() {
  // 画像プレビュー機能
  window.previewImage = function(input) {
    const file = input.files[0];
    const preview = document.getElementById('image-preview');
    
    if (file) {
      const reader = new FileReader();
      reader.onload = function(e) {
        preview.innerHTML = `
          <img src="${e.target.result}" class="w-full h-full object-cover rounded-2xl" />
        `;
      };
      reader.readAsDataURL(file);
    }
  };

  // プロフィール画像プレビュー機能
  window.previewProfileImage = function(input, gender) {
    const file = input.files[0];
    const preview = document.getElementById(`profile-preview-${gender}`);
    
    if (file) {
      const reader = new FileReader();
      reader.onload = function(e) {
        preview.innerHTML = `
          <img src="${e.target.result}" class="w-full h-full object-cover" alt="プロフィール画像" />
        `;
      };
      reader.readAsDataURL(file);
    }
  };

  // 背景画像の高さ調整
  function adjustBackgroundImageHeight() {
    const coupleContainer = document.getElementById('couple-info-container');
    const bgImage = document.querySelector('.couple-bg-image');
    
    console.log('Container:', coupleContainer);
    console.log('Background image element:', bgImage);
    
    if (bgImage) {
      const bgImageStyle = bgImage.style.backgroundImage;
      console.log('Background image style:', bgImageStyle);
      
      if (bgImageStyle && bgImageStyle !== 'none') {
        const bgImageUrl = bgImageStyle.slice(5, -2);
        console.log('Background image URL:', bgImageUrl);
        
        const img = new Image();
        img.onload = function() {
          console.log('Image loaded - width:', this.naturalWidth, 'height:', this.naturalHeight);
          
          const containerWidth = coupleContainer.offsetWidth;
          console.log('Container width:', containerWidth);
          
          const aspectRatio = this.naturalHeight / this.naturalWidth;
          const calculatedHeight = containerWidth * aspectRatio;
          console.log('Calculated height:', calculatedHeight);
          
          const finalHeight = Math.min(Math.max(calculatedHeight, 200), 600);
          console.log('Final height:', finalHeight);
          
          coupleContainer.style.height = finalHeight + 'px';
        };
        img.onerror = function() {
          console.error('Failed to load image:', bgImageUrl);
        };
        img.src = bgImageUrl;
      } else {
        console.log('No background image found');
      }
    } else {
      console.log('Background image element not found');
    }
  }


  // パララックス効果の実装
  function initParallaxEffects() {
    const parallaxElements = document.querySelectorAll('.parallax-slow, .parallax-fast');
    
    if (parallaxElements.length === 0) return;
    
    let ticking = false;
    
    function updateParallax() {
      const scrolled = window.pageYOffset;
      
      parallaxElements.forEach(element => {
        const speed = element.classList.contains('parallax-slow') ? 0.5 : 1;
        const yPos = -(scrolled * speed);
        element.style.transform = `translateY(${yPos}px)`;
      });
      
      ticking = false;
    }
    
    function requestTick() {
      if (!ticking) {
        requestAnimationFrame(updateParallax);
        ticking = true;
      }
    }
    
    window.addEventListener('scroll', requestTick);
  }

  // ウィンドウリサイズ時の背景画像調整
  window.addEventListener('resize', function() {
    adjustBackgroundImageHeight();
  });

  // スクロールアニメーションの実装
  function initScrollAnimations() {
    const observerOptions = {
      threshold: 0.1,
      rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('animate-in');
        }
      });
    }, observerOptions);
    
    // スクロールアニメーション対象の要素を監視
    const scrollElements = document.querySelectorAll('.scroll-animate, .scroll-animate-left, .scroll-animate-right, .scroll-animate-scale');
    scrollElements.forEach(el => observer.observe(el));
  }

  // 初期化
  adjustBackgroundImageHeight();
  initScrollAnimations();
  initParallaxEffects();
});