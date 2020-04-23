package com.codesquad.sidedish1.presentation;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.http.HttpServletResponse;
import javax.websocket.server.PathParam;

@RestController
public class LoginController {
    private static final Logger log = LoggerFactory.getLogger(LoginController.class);
    private LoginService loginService;

    public LoginController(LoginService loginService) {
        this.loginService = loginService;
    }

    @Autowired
    TokenRepository tokenRepository;

    @GetMapping("/githublogin")
    public ResponseEntity<String> githubLogin(@PathParam("code") String code, HttpServletResponse response) {
        log.info("##### code: {}", code);
        AccessTokenResponseSuccess accessTokenResponseSuccess = loginService.getAccessToken(code);
        response.setHeader("Authorization", accessTokenResponseSuccess.getAuthorization());
        Token token = new Token(accessTokenResponseSuccess.getAuthorization());
        tokenRepository.save(token);
        return ResponseEntity.ok("logined");
    }



}
