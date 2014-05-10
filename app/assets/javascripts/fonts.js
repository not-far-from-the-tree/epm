// everything in this file borrowed from source of http://notfarfromthetree.org/

(function() {
    var path = '//easy.myfonts.net/v1/js?sid=216028(font-family=ITC+Officina+Sans+Std+Display+Light)&sid=216031(font-family=ITC+Officina+Sans+Std+Bold)&sid=216033(font-family=ITC+Officina+Sans+Std+Book)&sid=216037(font-family=ITC+Officina+Sans+Std+Medium)&key=t8OnDDOYpy',
        protocol = ('https:' == document.location.protocol ? 'https:' : 'http:'),
        trial = document.createElement('script');
    trial.type = 'text/javascript';
    trial.async = true;
    trial.src = protocol + path;
    var head = document.getElementsByTagName("head")[0];
    head.appendChild(trial);
})();

(function() {
    var path = '//easy.myfonts.net/v1/js?sid=2718(font-family=Officina+Serif+Book)&sid=215186(font-family=ITC+Officina+Serif+Std+Book)&sid=216041(font-family=ITC+Officina+Serif+Std+Bold)&sid=216046(font-family=ITC+Officina+Serif+Std+Medium)&key=Y4vBJcZLkc',
        protocol = ('https:' == document.location.protocol ? 'https:' : 'http:'),
        trial = document.createElement('script');
    trial.type = 'text/javascript';
    trial.async = true;
    trial.src = protocol + path;
    var head = document.getElementsByTagName("head")[0];
    head.appendChild(trial);
})();