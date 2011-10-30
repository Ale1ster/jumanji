/* See LICENSE file for license and copyright information */

#include <girara/completion.h>
#include <girara/datastructures.h>
#include <girara/session.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <libgen.h>

#include "completion.h"
#include "database.h"
#include "utils.h"

girara_completion_t*
cc_open(girara_session_t* session, const char* input)
{
  g_return_val_if_fail(session != NULL, NULL);
  g_return_val_if_fail(session->global.data != NULL, NULL);
  jumanji_t* jumanji = session->global.data;

  girara_completion_t* completion  = girara_completion_init();
  girara_completion_group_t* group = NULL;

  if (completion == NULL) {
    goto error_free;
  }

  /* search history */
  girara_list_t* bookmark_list = jumanji_db_bookmark_find(jumanji->database, input);

  if (bookmark_list != NULL) {
    int bookmark_length = girara_list_size(bookmark_list);

    /* add group entry */
    if (bookmark_length > 0) {
      group = girara_completion_group_create(session, "Bookmarks");
      if (group == NULL) {
        goto error_free;
      } else {
        for (int i = 0; i < bookmark_length; i++) {
          jumanji_db_result_link_t* link = (jumanji_db_result_link_t*) girara_list_nth(bookmark_list, i);
          if (link != NULL) {
            girara_completion_group_add_element(group, link->url, link->title);
          }
        }

        girara_completion_add_group(completion, group);
      }
    }

    girara_list_free(bookmark_list);
  }

  /* search bookmarks */
  group                       = NULL;
  girara_list_t* history_list = jumanji_db_history_find(jumanji->database, input);

  if (history_list != NULL) {
    int history_length = girara_list_size(history_list);

    /* add group entry */
    if (history_length > 0) {
      group = girara_completion_group_create(session, "History");
      if (group == NULL) {
        goto error_free;
      } else {
        for (int i = 0; i < history_length; i++) {
          jumanji_db_result_link_t* link = (jumanji_db_result_link_t*) girara_list_nth(history_list, i);
          if (link != NULL) {
            girara_completion_group_add_element(group, link->url, link->title);
          }
        }

        girara_completion_add_group(completion, group);
      }
    }

    girara_list_free(history_list);
  }


  return completion;

error_free:

  if (completion != NULL) {
    girara_completion_free(completion);
  }

  if (group != NULL) {
    girara_completion_group_free(group);
  }

  return NULL;
}
